mod color;
mod ui;

use clap::{ Parser, Subcommand, Args as ClapArgs };
use color::{ StkColor, ColorVariant };
use ui::print_text_inline;

use crate::ui::print_log;

#[derive(ClapArgs, Debug)]
struct TextArgs {
    text: Vec<String>,
}

#[derive(Subcommand, Debug)]
enum Commands {
    #[command(name = "log", about = "Imprimir los logs de tu script para debugar")]
    Log {
        #[command(flatten)]
        text: TextArgs,

        #[arg(short, long, value_enum, default_value_t = ColorVariant::Log, help = "Variante del log")]
        variant: ColorVariant
    }
}

#[derive(Parser, Debug)]
#[command(name = "stk", version, about = "Kit de herramientas para shell scripts")]
struct Args {
    #[command(flatten)]
    text: TextArgs,

    #[arg(short, long, value_enum, default_value_t = StkColor::Green, help = "Color del texto de la terminal")]
    foreground: StkColor,

    #[arg(short, long, help = "Efecto bold en el texto de la terminal")]
    bold: bool,

    #[command(subcommand)]
    command: Option<Commands>
}


fn main() {
    let args = Args::parse();
    match args.command {
        Some(Commands::Log{ text, variant }) => {
            print_log(text.text, variant);
        }
        None => {
            print_text_inline(args.text.text, args.foreground, args.bold);
        }
    }
}
