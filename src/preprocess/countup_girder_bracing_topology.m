function girder_bracing = countup_girder_bracing_topology(com)
%countup_girder_bracing_topology - 梁の鉛直補剛点トポロジーを数え上げ
%
%   girder_bracing = countup_girder_bracing_topology(com) は、名目梁の
%   内部セグメント境界ごとに、鉛直方向の補剛点とみなすかを判定する。
%   判定は接続部材の種別だけで決まり、断面寸法や形状更新後の部材長に
%   は依存しない。
%
%   入力引数:
%     com - 共通オブジェクト
%
%   出力引数:
%     girder_bracing - 梁補剛点トポロジー (struct)
%       .vertical - 鉛直方向で補剛点となる内部境界
%                   [nnmg×(maxsub-1) logical]
%
%   備考:
%     - 柱と鉛直ブレースの取付節点を鉛直方向の補剛点とする
%     - 水平ブレースと直交梁は鉛直方向の補剛点に含めない
%     - 解析分割だけの境界（接続部材なし）は補剛点としない
%     - 元部材番号idmeg0が同じ境界でも、取付があれば補剛点とする

% 共通配列
nominal_girder = com.nominal.girder;
idnmg2mg = nominal_girder.idmeg;
idmg2m = com.member.girder.idme;
je = com.member.property.idnode2;

% 補剛材とみなす部材の取付節点
column_node = [com.member.column.idnode1; com.member.column.idnode2];
brace_node = [com.member.brace.idnode1; com.member.brace.idnode2];
bracing_node = unique([column_node; brace_node]);

% 定数
nnmg = size(idnmg2mg, 1);
nbound = max(1, size(idnmg2mg, 2) - 1);

braced_vertical = false(nnmg, nbound);

for inmg = 1:nnmg
  nsub = nnz(idnmg2mg(inmg, :));
  igs = idnmg2mg(inmg, 1:nsub);

  for k = 1:nsub-1
    % 境界節点はk番目セグメントの終端
    node = je(idmg2m(igs(k)));
    braced_vertical(inmg, k) = any(bracing_node == node);
  end
end

girder_bracing.vertical = braced_vertical;

return
end
