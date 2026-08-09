function [nominal_story, idstory2nominal] = countup_nominal_story(com)
%countup_nominal_story - 通常層の数え上げと層→通常層の写像
%
%   [nominal_story, idstory2nominal] = countup_nominal_story(com) は、
%   ダミー層を除いた通常層を数え上げ、層番号から通常層番号への
%   変換表を返す。ダミー層は依存先を通常層に達するまで辿る。
%   この変換表が com.story.idnominal の正本であり、断面の他層参照
%   とブレース配置はいずれもこの写像を層番号で引く。
%
%   入力引数:
%     com - 共通オブジェクト（story.isdummy,
%           story.id_dependent_story, story.name を参照）
%
%   出力引数:
%     nominal_story   - 通常層テーブル（name, idstory）
%     idstory2nominal - 層番号→通常層番号の変換表 [nstory×1]

% 共通定数
nstory = com.nstory;
story = com.story;

% 通常層を数え上げる
nnstory = sum(story.isdummy==false);
id = 0;
name = cell(nnstory,1);
idstory = zeros(nnstory,1);
for ist=1:nstory
  if story.isdummy(ist)
    continue
  end
  id = id+1;
  idstory(id) = ist;
  name{id} = story.name{ist};
end

% ID変換用: 層番号→通常層番号
idstory2nominal = zeros(nstory,1);
idstory2nominal(idstory) = 1:nnstory;
for ist=1:nstory
  if story.isdummy(ist)
    % 通常層が見つかるまで連鎖を辿る
    idep = story.id_dependent_story(ist);
    while story.isdummy(idep)
      idep = story.id_dependent_story(idep);
    end
    idstory2nominal(ist) = idstory2nominal(idep);
  end
end

% 結果の整理
nominal_story = table(name, idstory);
return
end
