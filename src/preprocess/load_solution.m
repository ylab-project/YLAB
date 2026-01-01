function x = load_solution(filename)
% 列数が異なる行を持つファイルを行優先で読み込む
% タブ/スペース区切り、カンマ区切り(CSV)の両方に対応
text = fileread(filename);
text = strrep(text, ',', ' ');
x = sscanf(text, '%f')';
end

