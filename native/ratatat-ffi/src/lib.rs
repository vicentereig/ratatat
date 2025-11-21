use crossterm::{
    cursor::MoveTo,
    event::{self, Event, KeyCode, KeyEventKind, KeyModifiers},
    execute,
    terminal::{self, Clear, ClearType, EnterAlternateScreen, LeaveAlternateScreen},
};
use std::{
    ffi::CStr,
    io::{stdout, Write},
    os::raw::{c_char, c_int, c_uint},
    time::Duration,
};

#[repr(C)]
pub struct Context {}

#[repr(C)]
pub struct RtEvent {
    pub kind: i32,     // 1 = key
    pub code: c_uint,  // KeyCode::Char as byte, or other key codes enumerated below
    pub modifiers: c_uint,
}

#[no_mangle]
pub extern "C" fn rt_size(_ctx: *mut Context, out_cols: *mut c_uint, out_rows: *mut c_uint) -> bool {
    if out_cols.is_null() || out_rows.is_null() {
        return false;
    }
    match terminal::size() {
        Ok((cols, rows)) => {
            unsafe {
                *out_cols = cols as c_uint;
                *out_rows = rows as c_uint;
            }
            true
        }
        Err(_) => false,
    }
}

#[no_mangle]
pub extern "C" fn rt_init() -> *mut Context {
    let _ = terminal::enable_raw_mode();
    let _ = execute!(stdout(), EnterAlternateScreen, Clear(ClearType::All));
    Box::into_raw(Box::new(Context {}))
}

#[no_mangle]
pub extern "C" fn rt_shutdown(ctx: *mut Context) {
    if ctx.is_null() {
        return;
    }
    unsafe { drop(Box::from_raw(ctx)) };
    let _ = execute!(stdout(), LeaveAlternateScreen, Clear(ClearType::All));
    let _ = terminal::disable_raw_mode();
}

/// Render a newline-separated buffer of UTF-8 text.
#[no_mangle]
pub extern "C" fn rt_render_lines(_ctx: *mut Context, text: *const c_char, count: c_int) {
    if text.is_null() {
        return;
    }
    let c_str = unsafe { CStr::from_ptr(text) };
    let Ok(body) = c_str.to_str() else { return };
    let mut out = stdout();
    let _ = execute!(out, MoveTo(0, 0), Clear(ClearType::All));
    for (row, line) in body.split('\n').take(count as usize).enumerate() {
        let _ = execute!(out, MoveTo(0, row as u16));
        let _ = write!(out, "{line}");
    }
    let _ = out.flush();
}

/// Poll for keyboard events; returns true if an event was written to `out_event`.
#[no_mangle]
pub extern "C" fn rt_poll_event(ctx: *mut Context, timeout_ms: c_uint, out_event: *mut RtEvent) -> bool {
    if ctx.is_null() || out_event.is_null() {
        return false;
    }
    let timeout = Duration::from_millis(timeout_ms as u64);
    if !event::poll(timeout).unwrap_or(false) {
        return false;
    }
    match event::read() {
        Ok(Event::Key(key)) if key.kind == KeyEventKind::Press => {
            let mut evt = RtEvent { kind: 1, code: 0, modifiers: 0 };
            match key.code {
                KeyCode::Char(c) => {
                    evt.code = c as u32;
                }
                KeyCode::Esc => evt.code = 0x1B,
                KeyCode::Enter => evt.code = b'\n' as u32,
                KeyCode::Up => evt.code = 1001,
                KeyCode::Down => evt.code = 1002,
                KeyCode::Left => evt.code = 1003,
                KeyCode::Right => evt.code = 1004,
                _ => {}
            }
            let mut mods = 0;
            if key.modifiers.contains(KeyModifiers::CONTROL) {
                mods |= 0x1;
            }
            if key.modifiers.contains(KeyModifiers::ALT) {
                mods |= 0x2;
            }
            if key.modifiers.contains(KeyModifiers::SHIFT) {
                mods |= 0x4;
            }
            evt.modifiers = mods;
            unsafe { *out_event = evt };
            true
        }
        _ => false,
    }
}
