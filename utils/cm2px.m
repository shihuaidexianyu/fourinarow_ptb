function px = cm2px(cm, px_per_cm)
%CM2PX 厘米 → 像素（四舍五入取整）。

px = round(cm .* px_per_cm);
end
