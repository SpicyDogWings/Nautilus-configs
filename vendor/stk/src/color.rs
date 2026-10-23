use clap::{ ValueEnum };
use anstyle::{ AnsiColor, Color };

#[derive(Clone, Debug, ValueEnum)]
pub enum StkColor {
    Red,
    Green,
    Blue,
    Cyan,
    Black,
    Yellow,
    Magenta,
    White,
    BrightBlue,
    BrightGreen,
    BrightRed,
    BrightCyan,
    BrightBlack,
    BrightYellow,
    BrightMagenta,
    BrightWhite
}

impl From<StkColor> for Color {
    fn from(c: StkColor) -> Self {
        match c {
            StkColor::Blue => AnsiColor::Blue.into(),
            StkColor::Red => AnsiColor::Red.into(),
            StkColor::Green => AnsiColor::Green.into(),
            StkColor::Cyan => AnsiColor::Cyan.into(),
            StkColor::Black => AnsiColor::Black.into(),
            StkColor::Yellow => AnsiColor::Yellow.into(),
            StkColor::Magenta => AnsiColor::Magenta.into(),
            StkColor::White => AnsiColor::White.into(),
            StkColor::BrightBlue => AnsiColor::BrightBlue.into(),
            StkColor::BrightRed => AnsiColor::BrightRed.into(),
            StkColor::BrightGreen => AnsiColor::BrightGreen.into(),
            StkColor::BrightCyan => AnsiColor::BrightCyan.into(),
            StkColor::BrightBlack => AnsiColor::BrightBlack.into(),
            StkColor::BrightYellow => AnsiColor::BrightYellow.into(),
            StkColor::BrightMagenta => AnsiColor::BrightMagenta.into(),
            StkColor::BrightWhite => AnsiColor::BrightWhite.into(),
        }

    }
    
}

#[derive(Clone, Debug, ValueEnum)]
pub enum ColorVariant {
   Log,
   Error,
   Warning,
   Success,
   Debug
}

impl From<ColorVariant> for StkColor {
    fn from(c: ColorVariant) -> Self {
        match c {
            ColorVariant::Log => StkColor::Blue.into(),
            ColorVariant::Error => StkColor::Red.into(),
            ColorVariant::Warning => StkColor::Yellow.into(),
            ColorVariant::Success => StkColor::Green.into(),
            ColorVariant::Debug => StkColor::BrightBlack.into()
        }
    }
}

impl ColorVariant {
    pub fn label(&self) -> &'static str {
        match self {
            ColorVariant::Log => "LOG",
            ColorVariant::Error => "ERR",
            ColorVariant::Warning => "WARN",
            ColorVariant::Success => "SUCC",
            ColorVariant::Debug => "DEBG"
        }
        
    }
}
