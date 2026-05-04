function s = make_section_symbol(sec, i)
%make_section_symbol - 添字prefix付き断面符号文字列を生成
%
%   s = make_section_symbol(sec, i) は、断面構造体 sec の i 番目の
%   subindex_raw と name を連結した符号文字列を返す。subindex_raw が
%   '-' のときは prefix を付けず name のみを返す。SS7 出力と一致。
%
%   入力引数:
%     sec - 断面構造体（subindex_raw / name フィールドを持つ）
%     i   - 断面のインデックス
%
%   出力引数:
%     s   - 添字付き符号文字列（例: 'RG1', 'G1'）

sub = sec.subindex_raw{i};
if strcmp(sub, '-')
  sub = '';
end
s = [sub sec.name{i}];

end

