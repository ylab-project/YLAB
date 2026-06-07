function beta = calc_brace_force_share_ratio(frame_shear_ratio)
%calc_brace_force_share_ratio - ブレース水平力分担率βを算出
%
%   beta = calc_brace_force_share_ratio(frame_shear_ratio) は、
%   柱座屈長さ係数補正で参照するブレース水平力分担率βを返す。
%   frame_shear_ratio の層合計負担率 Qw_Qcw_total を、各内部story
%   から出力対象階(output_idstory)へ写像して [story×lc] とする。
%   これにより、水平力分担表に出る出力階のβを、ダミー階直上の
%   非出力storyの柱も参照できる。
%
%   入力引数:
%     frame_shear_ratio - 階別・フレーム別集計 (struct)。
%                         calc_frame_shear_ratio の戻り値。
%
%   出力引数:
%     beta - ブレース水平力分担率 [nstory×nlc]

% 各内部storyを出力対象階のβへ写像する
beta = frame_shear_ratio.Qw_Qcw_total( ...
  frame_shear_ratio.output_idstory, :);

return
end
