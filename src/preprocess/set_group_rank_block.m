function floor = set_group_rank_block(dbc, floor, options)
%set_group_rank_block - 部材群種別の階別指定を読み込む
%
%   floor = set_group_rank_block(dbc, floor, options) は、一般階へ
%   一括指定を適用し、個別指定のある項目だけ上書きする。対象外階の
%   要求種別は0とし、個別指定の重複・範囲・値は読込時に検査する。
%
%   入力引数:
%     dbc     - 入力ブロック取得オブジェクト
%     floor   - 階データのtable
%     options - 一括指定、地下階数、PH階数を含む計算条件
%
%   出力引数:
%     floor - rank_groupとFA・FC割合の余裕率を加えた階データ

coptions = options.coptions;
idfloor = find(~floor.isdummy);
idfloor = idfloor(1+options.num_basement_floor: ...
  end-options.num_penthouse_floor);
floor.rank_group = zeros(numel(floor.idz), 1);
floor.rank_group(idfloor) = coptions.rank_group;
floor.alfa_group_fa = coptions.alfa_group_rank * ones(numel(floor.idz), 1);
floor.alfa_group_fc = floor.alfa_group_fa;

data = dbc.get_data_block('部材群種別制約の個別指定');
if size(data, 1) > 1
  [~, idfirst] = unique(data(:, 1), 'stable');
  idduplicate = setdiff(1:size(data, 1), idfirst);
  if ~isempty(idduplicate)
    throw_err('Input', 'DuplicateGroupRankInput', ...
      '部材群種別制約の個別指定', idduplicate(1), '階名');
  end
end
for i = 1:size(data, 1)
  ifl = find(matches(floor.name, data{i, 1}));
  if isempty(ifl) || ~ismember(ifl, idfloor)
    throw_err('Input', 'InvalidGroupRankFloor', ...
      '部材群種別制約の個別指定', i);
  end
  if ~ismissing(data{i, 2})
    rank = find(matches(PRM.GROUP_RANK_NAME( ...
      PRM.GROUP_RANK_A:PRM.GROUP_RANK_C), data{i, 2}));
    if isempty(rank)
      throw_err('Input', 'InvalidGroupRank', ...
        '部材群種別制約の個別指定', i);
    end
    floor.rank_group(ifl) = rank;
  end
  % D列は読込器が数値・空欄へ正規化済み。ここでは余裕率の範囲を検査
  alfa = [data{i, 3:4}];
  if any(alfa < 0 | alfa >= 1)
    throw_err('Input', 'InvalidGroupRankMargin', ...
      '部材群種別制約の個別指定', i);
  end
  if ~isnan(alfa(1))
    floor.alfa_group_fa(ifl) = alfa(1);
  end
  if ~isnan(alfa(2))
    floor.alfa_group_fc(ifl) = alfa(2);
  end
end

if coptions.consider_group_rank && ...
    (~coptions.consider_slenderness_ratio || ...
    ~coptions.consider_joint_bearing_strength)
  throw_warn('Input', 'GroupRankConditionsDisabled');
end

return
end
