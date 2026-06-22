function type_name = normalize_ss7_steel_type_name(type_name)
%normalize_ss7_steel_type_name - 鋼材種類名をSS7表記へ寄せる
%
%   type_name = normalize_ss7_steel_type_name(type_name) は、
%   YLAB内部の鋼材種類名をSS7出力CSVの表記へ変換する。

switch type_name
  case 'スーパーハイスレンドH'
    type_name = 'ｽｰﾊﾟｰﾊｲｽﾚﾝﾄﾞH';
end

return
end