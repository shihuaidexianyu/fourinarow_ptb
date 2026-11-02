function draw_fixation_screen(ui, config, layout)
%DRAW_FIXATION_SCREEN 绘制注视点页面（居中）。
%   按视觉角度绘制十字注视点。

Screen('FillRect', ui.win, ui.colors.bg);
draw_angle_cross_fixation(ui, config, layout);
end

function draw_angle_cross_fixation(ui, config, layout)
%DRAW_ANGLE_CROSS_FIXATION 按视觉角度绘制十字注视点。

len_cm = deg2cm(config.ui.fixation_deg, config.display.viewing_distance_cm);
thick_cm = deg2cm(config.ui.fixation_thickness_deg, config.display.viewing_distance_cm);

len_px = max(6, cm2px(len_cm, layout.px_per_cm));
thick_px = max(2, cm2px(thick_cm, layout.px_per_cm));

rect = ui.screen_rect;
cx = round((rect(1) + rect(3)) / 2);
cy = round((rect(2) + rect(4)) / 2);
half_len = round(len_px / 2);

Screen('DrawLine', ui.win, ui.colors.text, cx - half_len, cy, cx + half_len, cy, thick_px);
Screen('DrawLine', ui.win, ui.colors.text, cx, cy - half_len, cx, cy + half_len, thick_px);
end
