function x = generate_random_initial_solution(standardAccessor, ...
  idMapper, secList, seed, lm, options)
%generate_random_initial_solution ランダム初期解を生成
%   x = generate_random_initial_solution(standardAccessor, ...
%     idMapper, secList, seed, lm, options) は、
%   最適化アルゴリズム用のランダム初期解を生成します。
%
%   入力引数:
%     standardAccessor - SectionStandardAccessorインスタンス
%     idMapper - IdMapperインスタンス
%     secList - SectionListHandlerインスタンス
%     seed - 乱数シード (省略時はshuffle)
%     lm - 部材長さ配列 [nme×1] (省略可能)
%     options - オプション構造体 (省略可能)
%       .do_limit_initial_girder_height - 梁せい制限フラグ
%
%   出力引数:
%     x - 設計変数ベクトル [1×nxvar]

% 引数の既定値処理
if nargin < 4 || isempty(seed)
  rng('shuffle');
else
  rng(seed);
end

if nargin < 5
  lm = [];
end

if nargin < 6
  options = struct('do_limit_initial_girder_height', false);
end

% 必要な情報の取得
nxvar = idMapper.nxvar;
isVarofSlist = idMapper.getIsVarofSlist();
idvar2vtype = idMapper.idvar2vtype;
nlist = secList.nlist;

% 初期化
x = zeros(1, nxvar);

% 梁せい制限の判定
doLimitH = ~isempty(lm) && ...
  isfield(options, 'do_limit_initial_girder_height') && ...
  options.do_limit_initial_girder_height;

% 梁せい制限が必要な場合の準備
if doLimitH
  idme2var = idMapper.idme2var(:,1);
else
  idme2var = [];
end

% 各断面リストを処理
for idlist = 1:nlist
  % WFS_H（梁せい）の処理
  x = processWfsH(x, idlist, standardAccessor, isVarofSlist, ...
    idvar2vtype, doLimitH, lm, idme2var);
  
  % その他の変数タイプの処理
  x = processOtherVariables(x, idlist, standardAccessor, ...
    isVarofSlist, idvar2vtype);
end

return

%% WFS_H処理
function x = processWfsH(x, idlist, standardAccessor, isVarofSlist, ...
  idvar2vtype, doLimitH, lm, idme2var)
  
  % 対象変数の特定
  ivvv = 1:length(x);
  idH2v = ivvv(isVarofSlist(:,idlist) & ...
    idvar2vtype == PRM.WFS_H);
  
  if isempty(idH2v)
    return;
  end
  
  % 名目値の取得
  Hnominal = standardAccessor.getNominalH(idlist);
  if isempty(Hnominal)
    return;
  end
  
  % 各変数に値を設定
  for i = 1:length(idH2v)
    idv = idH2v(i);
    
    % 候補値の決定
    if doLimitH && ~isempty(idme2var)
      % スパン制限を適用
      lmg = lm(idme2var == idv);
      if ~isempty(lmg)
        Hub = max(lmg / 10);
        Hlb = max(lmg / 20);
        candidates = Hnominal(Hnominal >= Hlb & Hnominal <= Hub);
        if isempty(candidates)
          candidates = Hnominal;  % 範囲内になければ全候補
        end
      else
        candidates = Hnominal;
      end
    else
      candidates = Hnominal;
    end
    
    % ランダム選択
    x(idv) = candidates(randi(length(candidates)));
  end
  
  return
end

%% その他の変数処理
function x = processOtherVariables(x, idlist, standardAccessor, ...
  isVarofSlist, idvar2vtype)
  
  % 変数タイプと取得メソッドの対応
  vtypeConfigs = [
    struct('vtype', PRM.WFS_B, 'method', @getNominalB), ...
    struct('vtype', PRM.WFS_TW, 'method', @getStandardTw), ...
    struct('vtype', PRM.WFS_TF, 'method', @getStandardTf), ...
    struct('vtype', PRM.HSS_D, 'method', @getStandardD), ...
    struct('vtype', PRM.HSS_T, 'method', @getStandardT)
  ];
  
  ivvv = 1:length(x);
  
  for config = vtypeConfigs
    % 対象変数の特定
    idtarget = ivvv(isVarofSlist(:,idlist) & ...
      idvar2vtype == config.vtype);
    
    if isempty(idtarget)
      continue;
    end
    
    % 値の取得
    values = config.method(standardAccessor, idlist);
    if isempty(values)
      continue;
    end
    
    % ランダム選択
    x(idtarget) = values(randi(length(values), 1, length(idtarget)));
  end
  
  return
end

end