# Tareas pendientes v0.3.0-alpha

## - [ ] Usar ratatui

Investigar sobre esta implementación de ratatui para crear ui inline

``` rs
let backend = CrosstermBackend::new(std::io::stdout());
let mut terminal = Terminal::with_options(backend, TerminalOptions {
    viewport: Viewport::Inline(8),
})?;
```

## - [x] Ayuda en los flags

Agregar help key a las flags en los #[args()] de los flags para mostrar la ayuda
