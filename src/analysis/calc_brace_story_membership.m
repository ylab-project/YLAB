function brace_in_story = calc_brace_story_membership(com)
%calc_brace_story_membership - 名目ブレースが跨ぐ階の判定
%
%   brace_in_story = calc_brace_story_membership(com) は、各名目
%   ブレースが鉛直方向に跨ぐ階を logical 行列で返す。多層ブレースは
%   idz スパンを階上端z (com.story.idz) で展開し、跨ぐ全階を true と
%   する。水平力分担率βおよび水平力分担表の層集計で、ブレース水平力
%   を跨ぐ各階に計上するために用いる。
%
%   入力引数:
%     com - 共通オブジェクト（nominal.brace, member.brace, story を含む）
%
%   出力引数:
%     brace_in_story - 跨ぐ階フラグ [nnb×nstory] logical

nstory = com.nstory;
nbrace = com.nominal.brace;
nnb = size(nbrace, 1);
brace_in_story = false(nnb, nstory);

% ブレースがない場合は空の判定を返す
if nnb == 0
  return
end

mbrace_idz = com.member.brace.idz;
story_idz = com.story.idz(:)';

% 各名目ブレースの idz スパンを階上端z で展開し、跨ぐ階を判定する。
% idmeb には 0 が入り得る(K下片側等)ため、有効 member のみ抽出して
% member.brace.idz を参照する。判定は bz < story.idz <= tz。
for inb = 1:nnb
  imeb = nbrace.idmeb(inb, :);
  imeb = imeb(imeb > 0);
  bz = min(mbrace_idz(imeb, 1));
  tz = max(mbrace_idz(imeb, 2));
  brace_in_story(inb, :) = story_idz > bz & story_idz <= tz;
end

return
end
