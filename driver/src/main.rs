use eframe::egui;
use std::io::{self, Read, Write};
use std::net::TcpStream;
use std::time::Duration;
use toml;

enum Connection {
    Serial(Box<dyn serialport::SerialPort>),
    Tcp(std::net::TcpStream),
}

impl Read for Connection {
    fn read(&mut self, buf: &mut [u8]) -> std::io::Result<usize> {
        match self {
            Connection::Serial(port) => port.read(buf),
            Connection::Tcp(stream) => stream.read(buf),
        }
    }
}

impl Write for Connection {
    fn write(&mut self, buf: &[u8]) -> std::io::Result<usize> {
        match self {
            Connection::Serial(port) => port.write(buf),
            Connection::Tcp(stream) => stream.write(buf),
        }
    }

    fn flush(&mut self) -> std::io::Result<()> {
        match self {
            Connection::Serial(port) => port.flush(),
            Connection::Tcp(stream) => stream.flush(),
        }
    }
}

#[derive(PartialEq)]
enum ConnectionMode {
    Serial,
    Tcp,
}

#[derive(Debug, serde::Serialize, serde::Deserialize)]
struct Config {
    com_port: String,
    baud_rate: u32,
    log_path: String,
}

fn settings_path() -> std::path::PathBuf {
    let execute_path = std::env::current_exe().expect("Failed to get current executable path");
    execute_path
        .parent()
        .expect("Failed to get parent directory")
        .join("settings.toml")
}

fn main() {
    if cfg!(not(target_os = "windows")) {
        panic!("This driver is only supported on Windows.");
    }

    let setting_path = settings_path();

    if !setting_path.exists() {
        std::fs::write(
            &setting_path,
            r#"com_port = "COM3"
log_path = "C:/jmOS_logs"
baud_rate = 115_200
"#,
        )
        .expect("Failed to create default settings.toml");
    }

    let options = eframe::NativeOptions {
        viewport: egui::ViewportBuilder::default()
            .with_inner_size([400.0, 300.0])
            .with_min_inner_size([300.0, 200.0]),
        ..Default::default()
    };
    let _ = eframe::run_native(
        "uart_log_driver",
        options,
        Box::new(|cc| Ok(Box::new(UartLogApp::new(cc)))),
    );
}

struct UartLogApp {
    log_path: String,
    selected_port: String,
    available_ports: Vec<String>,
    status_message: String,
    mode: ConnectionMode,
    tcp_address: String,
    connection: Option<Connection>,
}

impl Default for UartLogApp {
    fn default() -> Self {
        Self {
            log_path: "C:/jmOS_logs".to_string(),
            selected_port: String::new(),
            available_ports: vec![],
            status_message: "Ready".to_owned(),

            mode: ConnectionMode::Tcp,
            tcp_address: "127.0.0.1:1234".to_string(),
            connection: None,
        }
    }
}

impl UartLogApp {
    fn new(_cc: &eframe::CreationContext<'_>) -> Self {
        let mut app = Self::default();

        let setting_path = settings_path();
        if let Ok(content) = std::fs::read_to_string(setting_path) {
            if let Ok(config) = toml::from_str::<Config>(&content) {
                app.log_path = config.log_path;
            }
        }

        app.refresh_ports();
        app
    }

    fn refresh_ports(&mut self) {
        match serialport::available_ports() {
            Ok(ports) => {
                self.available_ports = ports.iter().map(|p| p.port_name.clone()).collect();
                if !self.available_ports.is_empty() {
                    self.selected_port = self.available_ports[0].clone();
                }
            }
            Err(e) => {
                self.status_message = format!("Error listing ports: {}", e);
            }
        }
    }
}

impl eframe::App for UartLogApp {
    fn update(&mut self, ctx: &egui::Context, frame: &mut eframe::Frame) {
        if let Some(conn) = &mut self.connection {
            let mut buffer = [0u8; 1024];

            if let Connection::Tcp(stream) = conn {
                stream.set_nonblocking(true).ok();
            }

            match conn.read(&mut buffer) {
                Ok(bytes_read) if bytes_read > 0 => {
                    let log_data = String::from_utf8_lossy(&buffer[..bytes_read]);
                    let log_file_path = std::path::Path::new(&self.log_path).join("uart_log.txt");

                    if let Some(parent) = log_file_path.parent() {
                        std::fs::create_dir_all(parent).expect("Failed to create log directory");
                    }

                    let mut file = std::fs::OpenOptions::new()
                        .create(true)
                        .append(true)
                        .open(&log_file_path)
                        .expect("Failed to open log file");

                    write!(
                        file,
                        "{} >> {}\n",
                        std::time::SystemTime::now()
                            .duration_since(std::time::UNIX_EPOCH)
                            .unwrap()
                            .as_secs(),
                        log_data
                    )
                    .expect("Failed to write log data to file");
                }
                Err(ref e) if e.kind() == io::ErrorKind::WouldBlock => {
                    // No data available right now
                }
                Err(e) => {
                    eprintln!("Error reading from connection: {}", e);
                }
                _ => { /* No data read */ }
            }
        }

        egui::CentralPanel::default().show(ctx, |ui| {
            ui.heading("UART Log Driver");

            ui.horizontal(|ui| {
                ui.radio_value(&mut self.mode, ConnectionMode::Tcp, "TCP");
                ui.radio_value(&mut self.mode, ConnectionMode::Serial, "Serial");
            });

            ui.separator();

            match self.mode {
                ConnectionMode::Serial => {
                    ui.horizontal(|ui| {
                        ui.label("COM Port:");
                        egui::ComboBox::from_id_salt("port_selector")
                            .selected_text(&self.selected_port)
                            .show_ui(ui, |ui| {
                                for port in serialport::available_ports()
                                    .expect("Failed to list serial ports")
                                {
                                    let port_name = port.port_name;
                                    ui.selectable_value(
                                        &mut self.selected_port,
                                        port_name.clone(),
                                        port_name,
                                    );
                                }
                            });
                        if ui.button("Refresh").clicked() {
                            self.refresh_ports();
                        }
                    });
                }
                ConnectionMode::Tcp => {
                    ui.horizontal(|ui| {
                        ui.label("TCP Address:");
                        ui.text_edit_singleline(&mut self.tcp_address);
                    });
                }
            }
            ui.label(format!("Status: {}", self.status_message));
        });

        egui::TopBottomPanel::bottom("btn_ctx").show(ctx, |ui| {
            ui.horizontal(|ui| {
                if ui.button("SetSavePath").clicked() {
                    if let Some(path) = rfd::FileDialog::new()
                        .set_title("Select Log Directory")
                        .set_directory("C:/")
                        .pick_folder()
                    {
                        self.log_path = path.display().to_string();
                    }
                }
                let btn_label = if self.connection.is_some() {
                    "Disconnect"
                } else {
                    "Connect"
                };
                if ui.button(btn_label).clicked() {
                    if self.connection.is_some() {
                        self.connection = None;
                        self.status_message = "Disconnected".to_string();
                    } else {
                        // 接続処理
                        match self.mode {
                            ConnectionMode::Serial => {
                                match serialport::new(&self.selected_port, 115_200)
                                    .timeout(Duration::from_millis(10))
                                    .open()
                                {
                                    Ok(p) => {
                                        self.connection = Some(Connection::Serial(p));
                                        self.status_message = "Connected to Serial".to_string();
                                    }
                                    Err(e) => self.status_message = format!("Serial Error: {}", e),
                                }
                            }
                            ConnectionMode::Tcp => match TcpStream::connect(&self.tcp_address) {
                                Ok(s) => {
                                    s.set_nonblocking(true).ok();
                                    self.connection = Some(Connection::Tcp(s));
                                    self.status_message = "Connected to Renode".to_string();
                                }
                                Err(e) => self.status_message = format!("TCP Error: {}", e),
                            },
                        }
                    }
                }
            });
        });
    }

    fn on_exit(&mut self, _gl: Option<&eframe::glow::Context>) {
        let load_settings = settings_path();
        let mut config: Config = toml::from_str(
            &std::fs::read_to_string(&load_settings).expect("Failed to read settings.toml"),
        )
        .expect("Failed to parse settings.toml");
        config.log_path = self.log_path.clone();
        let toml_string = toml::to_string(&config).expect("Failed to serialize config to TOML");
        std::fs::write(&load_settings, toml_string).expect("Failed to write settings.toml");
    }
}
