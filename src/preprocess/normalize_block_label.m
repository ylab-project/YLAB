function label = normalize_block_label(label)
%normalize_block_label - ブロック名照合用に括弧の全角を半角へ揃える
%
%   label = normalize_block_label(label) は、ブロック名または
%   'name=<ラベル>' 文字列の全角括弧を半角括弧へ置換して返す。
%   ブロック名の照合と列定義の参照はこの正規化を共有する。
%
%   入力引数:
%     label - ブロック名の文字列
%
%   出力引数:
%     label - 括弧を半角へ正規化した文字列
label = replace(label, {'（', '）'}, {'(', ')'});

return
end
