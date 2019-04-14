use sdl2;
use std::{
    sync::Mutex,
    thread,
    time::{Duration, Instant},
};
use unicorn::{Cpu, CpuX86, Mode, Protection, RegisterX86};

const WINDOW_WIDTH: u32 = 640;
const WINDOW_HEIGHT: u32 = 480;
const LOGO_WIDTH: usize = 64;
const LOGO_HEIGHT: usize = 32;
const FRAME_TIME: Duration = Duration::from_millis(1000 / 30);

const VGA_PALETTE: [(u8, u8, u8); 16] = [
    (0x00, 0x00, 0x00), // 0
    (0x00, 0x00, 0xaa), // 1
    (0x00, 0xaa, 0x00), // 2
    (0x00, 0xaa, 0xaa), // 3
    (0xaa, 0x00, 0x00), // 4
    (0xaa, 0x00, 0xaa), // 5
    (0xaa, 0x55, 0x00), // 6
    (0xaa, 0xaa, 0xaa), // 7
    (0x55, 0x55, 0x55), // 8
    (0x55, 0x55, 0xff), // 9
    (0x55, 0xff, 0x55), // a
    (0x55, 0xff, 0xff), // b
    (0xff, 0x55, 0x55), // c
    (0xff, 0x55, 0xff), // d
    (0xff, 0xff, 0x55), // e
    (0xff, 0xff, 0xff), // f
];

fn main() {
    let sdl_context = sdl2::init().unwrap();
    let event_pump = Mutex::new(sdl_context.event_pump().unwrap());
    let canvas = {
        let video_subsystem = sdl_context.video().unwrap();
        let window = video_subsystem
            .window("realdvd", WINDOW_WIDTH, WINDOW_HEIGHT)
            .build()
            .unwrap();
        let mut canvas = window.into_canvas().software().build().unwrap();

        canvas.clear();

        Mutex::new(canvas)
    };
    let frame_start = Mutex::new(Instant::now());
    let pixel_count = Mutex::new(0);

    let mut emu = CpuX86::new(Mode::MODE_16).unwrap();
    emu.mem_map(0, 0x10000, Protection::ALL).unwrap();
    emu.add_intr_hook(move |unicorn, interrupt_num| {
        let mut canvas = canvas.lock().unwrap();
        let mut event_pump = event_pump.lock().unwrap();
        let mut frame_start = frame_start.lock().unwrap();
        let mut pixel_count = pixel_count.lock().unwrap();

        match interrupt_num {
            // video interrupts
            0x10 => {
                match unicorn.reg_read(RegisterX86::AH as i32).unwrap() {
                    // draw pixel
                    0x0c => {
                        let color = unicorn.reg_read(RegisterX86::AL as i32).unwrap();
                        let x = unicorn.reg_read(RegisterX86::CX as i32).unwrap();
                        let y = unicorn.reg_read(RegisterX86::DX as i32).unwrap();

                        canvas.set_draw_color(VGA_PALETTE[color as usize]);
                        canvas.draw_point((x as i32, y as i32)).unwrap();

                        *pixel_count += 1;
                        if *pixel_count == LOGO_WIDTH * LOGO_HEIGHT {
                            *pixel_count = 0;
                            if frame_start.elapsed() < FRAME_TIME {
                                thread::sleep(FRAME_TIME - frame_start.elapsed());
                                *frame_start = Instant::now();
                            }
                            canvas.present();
                        }

                        for event in event_pump.poll_iter() {
                            use sdl2::{event::Event, keyboard::Keycode};
                            match event {
                                Event::Quit { .. }
                                | Event::KeyDown {
                                    keycode: Some(Keycode::Escape),
                                    ..
                                } => unicorn.emu_stop().unwrap(),
                                _ => (),
                            }
                        }
                    }

                    // vesa vga bios call
                    // we just ignore it here because we know what we're wrapping and can make
                    // assumptions about the mode
                    0x4f => (),

                    // unimplemented/other
                    other => unimplemented!("interrupt 0x10/0x{:x}", other),
                }
            }

            // unimplemented/other
            _ => unimplemented!(),
        }
    })
    .unwrap();
    emu.mem_write(0x100, include_bytes!("../../dvd.com")).unwrap();
    emu.emu_start(0x100, 0, 0, 0).unwrap();
}
