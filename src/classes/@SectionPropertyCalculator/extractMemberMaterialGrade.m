function grade = extractMemberMaterialGrade(obj, secdim, matGrade, member)
%extractMemberMaterialGrade - 各部材の材料鋼種を抽出する
%
%   grade = extractMemberMaterialGrade(obj, secdim, matGrade, member) は、
%   断面の材料番号を部材へ対応させ、鋼種を返す。
%
%   入力引数:
%     obj      - 断面性能計算オブジェクト
%     secdim   - 全断面の寸法 [nsec×7]、第6・7列はリストと断面の番号
%     matGrade - 材料の鋼種 [nmat×1] (PRM.GRADE_SS/SN/SM)
%     member - 現在の解析部材。property.idsecは各部材の断面番号
%
%   出力引数:
%     grade - 各部材の鋼種 [nme×1]、未割当は0
%
%   参考:
%     extractMemberMaterialF, extractMemberMaterialId
% 入力チェック
if size(secdim, 2) < 7
  error('secdimは7列以上である必要があります');
end

% secdimからidsec2slistを抽出（第6,7列）
idsec2slist = secdim(:, ...
  [PRM.MAPPED_SECDIM_SLIST PRM.MAPPED_SECDIM_SECTION]);

% 材料IDの取得
idme2mat = obj.extractMemberMaterialId(idsec2slist, member);

% 鋼種の抽出
nme = length(idme2mat);
grade = zeros(nme, 1);
valid_idx = idme2mat > 0;
if any(valid_idx)
  grade(valid_idx) = matGrade(idme2mat(valid_idx));
end

return
end
