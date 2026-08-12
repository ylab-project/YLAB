function column_bracing = countup_column_bracing_topology(com)
%countup_column_bracing_topology - 柱の方向別補剛点トポロジーを数え上げ
%
%   column_bracing = countup_column_bracing_topology(com) は、名目柱の
%   内部セグメント境界ごとに、X方向・Y方向それぞれで補剛点とみなすか
%   を判定する。判定は接続部材の方向と基礎梁接続だけで決まり、断面
%   寸法や形状更新後の部材長には依存しない。
%
%   入力引数:
%     com - 共通オブジェクト
%
%   出力引数:
%     column_bracing - 柱補剛点トポロジー (struct)
%       .x - X方向で補剛点となる内部境界 [nnmc×(maxseg-1) logical]
%       .y - Y方向で補剛点となる内部境界 [nnmc×(maxseg-1) logical]
%
%   備考:
%     - 列kは名目柱のk番目セグメント上端の境界に対応する
%     - セグメント数が少ない名目柱の余剰列はfalseで埋める
%     - 補剛点の軸座標は形状更新後の部材長から分析層で生成する

% 共通配列
nominal_column = com.nominal.column;
idnmc2mc = nominal_column.idmec;
idmc2m = com.member.column.idme;
js = com.member.property.idnode1;
je = com.member.property.idnode2;
isxdir = com.cgsr.isxdir_member;
isydir = com.cgsr.isydir_member;
onfg_x = com.member.column.onfg_x;
onfg_y = com.member.column.onfg_y;

% 定数
nnmc = size(idnmc2mc, 1);
nbound = max(1, size(idnmc2mc, 2) - 1);

braced_x = false(nnmc, nbound);
braced_y = false(nnmc, nbound);

for inmc = 1:nnmc
  nseg = nnz(idnmc2mc(inmc, :));
  imcs = idnmc2mc(inmc, 1:nseg);

  for k = 1:nseg-1
    % 境界節点はk番目セグメントの上端
    node = je(idmc2m(imcs(k)));
    is_at_node = js == node | je == node;

    % 上側セグメントの基礎梁接続も補剛点として扱う
    braced_x(inmc, k) = any(is_at_node & isxdir) || onfg_x(imcs(k+1));
    braced_y(inmc, k) = any(is_at_node & isydir) || onfg_y(imcs(k+1));
  end
end

column_bracing.x = braced_x;
column_bracing.y = braced_y;

return
end
