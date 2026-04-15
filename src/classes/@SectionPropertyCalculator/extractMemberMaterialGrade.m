function grade = extractMemberMaterialGrade(obj, secdim, matGrade)
%extractMemberMaterialGrade 部材の材料鋼種を抽出
%   grade = extractMemberMaterialGrade(obj, secdim, matGrade) は、
%   断面寸法データと材料鋼種配列を使用して、各部材に対応する
%   鋼種（PRM.GRADE_SS/SN/SM）を抽出します。
%
%   入力引数:
%     secdim   - 断面寸法データ配列 [nsec × 7]
%     matGrade - 材料鋼種配列 [nmat × 1]
%
%   出力引数:
%     grade - 各部材の鋼種配列 [nmember × 1]
%
%   参考:
%     extractMemberMaterialF, getIdMemberToMaterial

% 入力チェック
if size(secdim, 2) < 7
  error('secdimは7列以上である必要があります');
end

% secdimからidsec2slistを抽出（第6,7列）
idsec2slist = secdim(:, 6:7);

% 材料IDの取得
idme2mat = obj.extractMemberMaterialId(idsec2slist);

% 鋼種の抽出
nme = length(idme2mat);
grade = zeros(nme, 1);
valid_idx = idme2mat > 0;
if any(valid_idx)
  grade(valid_idx) = matGrade(idme2mat(valid_idx));
end

return
end
