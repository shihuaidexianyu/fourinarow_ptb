function cm = deg2cm(theta_deg, distance_cm)
%DEG2CM 视觉角度（度）→ 物理尺寸（厘米）。
%   公式：cm = 2 * d * tan(theta/2)

cm = 2 .* distance_cm .* tan(deg2rad(theta_deg ./ 2));
end
