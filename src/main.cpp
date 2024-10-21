#include <iostream>
#include <SDL2/SDL.h>
#include <SDL2/SDL_mouse.h>
#include <SDL2/SDL_ttf.h>
#include <string>
#include <nlohmann/json.hpp>
#include <ogc/system.h>
#include <fstream>
#include "Roboto-Regular_ttf.h"
#include <lvgl.h>

using json = nlohmann::json;

#define SCREEN_WIDTH 640
#define SCREEN_HEIGHT 480

bool running = true;

lv_display_t* disp;
SDL_Event event;

SDL_GameController *controller = NULL;

void open_controller(int index) {
    if (SDL_IsGameController(index)) {
        controller = SDL_GameControllerOpen(index);
        if (controller) {
            printf("Manette %d connectée\n", index);
        } else {
            printf("Erreur lors de l'ouverture de la manette: %s\n", SDL_GetError());
        }
    }
}

void close_controller() {
    if (controller) {
        SDL_GameControllerClose(controller);
        controller = NULL;
        printf("Manette déconnectée\n");
    }
}

static void ta_event_cb(lv_event_t * e)
{
    lv_event_code_t code = lv_event_get_code(e);
    lv_obj_t * ta = static_cast<lv_obj_t*>(lv_event_get_target(e));
    lv_obj_t * kb = static_cast<lv_obj_t*>(lv_event_get_user_data(e));
    if(code == LV_EVENT_FOCUSED) {
        lv_keyboard_set_textarea(kb, ta);
        lv_obj_remove_flag(kb, LV_OBJ_FLAG_HIDDEN);
    }

    if(code == LV_EVENT_DEFOCUSED) {
        lv_keyboard_set_textarea(kb, NULL);
        lv_obj_add_flag(kb, LV_OBJ_FLAG_HIDDEN);
    }
}

void lv_example_keyboard_1(void)
{
    /*Create a keyboard to use it with an of the text areas*/
    lv_obj_t * kb = lv_keyboard_create(lv_screen_active());

    /*Create a text area. The keyboard will write here*/
    lv_obj_t * ta1;
    ta1 = lv_textarea_create(lv_screen_active());
    lv_obj_align(ta1, LV_ALIGN_TOP_LEFT, 10, 10);
    lv_obj_add_event_cb(ta1, ta_event_cb, LV_EVENT_ALL, kb);
    lv_textarea_set_placeholder_text(ta1, "Hello");
    lv_obj_set_size(ta1, 140, 80);

    lv_obj_t * ta2;
    ta2 = lv_textarea_create(lv_screen_active());
    lv_obj_align(ta2, LV_ALIGN_TOP_RIGHT, -10, 10);
    lv_obj_add_event_cb(ta2, ta_event_cb, LV_EVENT_ALL, kb);
    lv_obj_set_size(ta2, 140, 80);

    lv_keyboard_set_textarea(kb, ta1);

    /*The keyboard will show Arabic characters if they are enabled */
#if LV_USE_ARABIC_PERSIAN_CHARS && LV_FONT_DEJAVU_16_PERSIAN_HEBREW
    lv_obj_set_style_text_font(kb, &lv_font_dejavu_16_persian_hebrew, 0);
    lv_obj_set_style_text_font(ta1, &lv_font_dejavu_16_persian_hebrew, 0);
    lv_obj_set_style_text_font(ta2, &lv_font_dejavu_16_persian_hebrew, 0);
#endif
}

int main(int argc, char **argv) {
    // Redirection des printf vers les logs de Dolphin
    SYS_STDIO_Report(true);

    lv_init();

    disp = lv_sdl_window_create(SCREEN_WIDTH, SCREEN_HEIGHT);
    static uint8_t buf1[SCREEN_WIDTH * SCREEN_HEIGHT * 16];
    lv_display_set_buffers(disp, buf1, NULL, sizeof(buf1), LV_DISPLAY_RENDER_MODE_DIRECT);

    if (SDL_NumJoysticks() > 0) {
        open_controller(0);
    }

    void* rendererPtr = lv_sdl_window_get_renderer(disp);
    SDL_Renderer* renderer = static_cast<SDL_Renderer*>(rendererPtr);

    // Widget d'exemple
    lv_example_keyboard_1();

    auto lastTick = SDL_GetTicks();
    while (running) {
        if (SDL_PollEvent(&event)) {
            switch (event.type) {
                case SDL_QUIT:
                    running = false;
                    break;

                // Connexion d'une manette
                case SDL_CONTROLLERDEVICEADDED:
                    printf("container arone\n");
                    if (!controller) {
                        open_controller(event.cdevice.which);

                    }
                    break;

                // Déconnexion d'une manette
                case SDL_CONTROLLERDEVICEREMOVED:
                    if (controller && SDL_GameControllerGetJoystick(controller) == SDL_JoystickFromInstanceID(event.cdevice.which)) {
                        close_controller();
                    }
                    break;

                // Mouvement de la souris
                case SDL_MOUSEMOTION:
                    break;
            }

        }

        auto current = SDL_GetTicks();
        lv_tick_inc(current - lastTick);
        lastTick = current;
        lv_timer_handler();
    }

    // Libération des ressources
    lv_deinit();
    return 0;
}
