use crate::color::{ColorVariant, StkColor};
use anstyle::{ Effects, Style, Color};
use time::{
    OffsetDateTime,
    macros::format_description
};

pub fn print_text_inline(text: Vec<String>, color: StkColor, bold: bool) {
    let style = Style::new()
        .fg_color(Some(color.into()));
    let style = if bold { style.effects(Effects::BOLD) } else { style };
    print!("{style}{}{style:#}", text.join(" "));
}

pub fn print_log(text: Vec<String>, variant: ColorVariant) {
    let color: StkColor = variant.clone().into();
    let color: Color = color.into();
    let now = OffsetDateTime::now_local().unwrap_or_else(|_| OffsetDateTime::now_utc());
    let time_fmt = format_description!("[hour]:[minute]:[second]");
    let style = Style::new()
        .fg_color(Some(StkColor::Black.into()))
        .bg_color(Some(color.into()));
    let style2 = Style::new()
        .fg_color(Some(StkColor::White.into()));
    let style3 = Style::new()
        .fg_color(Some(StkColor::BrightBlack.into()));
    print!("{style} {} {style:#} {style3}{}{style3:#} {style2}{}{style2:#}", variant.label(), now.format(time_fmt).unwrap(), text.join(" "));
}
