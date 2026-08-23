function head = read_weight_category(class_name, usage_name, type_name)
%read_weight_category - 行頭3列を重量の区分・用途・タイプへ解釈する
%
%   head = read_weight_category(class_name, usage_name, type_name)
%   は、新形式ブロックの行頭3列（DL/LL・ラーメン用/地震用・タイプ）
%   を内部IDへ解釈する。空欄は DL/LL=直接値、用途=共通、タイプ=
%   床自重とする。DL/LL・用途の未知値は is_valid=false とし、呼び
%   出し側が行全体を反映せず警告する。タイプの未知値は床自重へ
%   フォールバックし unknown_type=true とする（内部設計5章）。
%
%   入力引数:
%     class_name - DL/LL列の値（char）
%     usage_name - ラーメン用/地震用列の値（char）
%     type_name  - タイプ列の値（char）
%
%   出力引数:
%     head - 解釈結果の構造体
%            .wclass       - PRM.WCLASS_*（未知は0）
%            .wusage       - PRM.WUSAGE_*（未知は0）
%            .wtype        - PRM.WTYPE_*
%            .is_valid     - DL/LL・用途とも解釈できた場合 true
%            .unknown_type - タイプ未知で床自重へ落とした場合 true
%            .is_unusual   - LLと通常外タイプの組合せの場合 true
head.wclass = 0;
switch class_name
  case 'LL'
    head.wclass = PRM.WCLASS_LL;
  case 'DL'
    head.wclass = PRM.WCLASS_DL;
  case ''
    head.wclass = PRM.WCLASS_DIRECT;
end
head.wusage = 0;
switch usage_name
  case ''
    head.wusage = PRM.WUSAGE_COMMON;
  case 'ラーメン用'
    head.wusage = PRM.WUSAGE_FRAME;
  case '地震用'
    head.wusage = PRM.WUSAGE_SEISMIC;
end
head.is_valid = head.wclass > 0 && head.wusage > 0;

head.unknown_type = false;
if isempty(type_name)
  head.wtype = PRM.WTYPE_FLOOR;
else
  idtype = find(strcmp(PRM.WTYPE_NAMES, type_name), 1);
  if isempty(idtype)
    head.wtype = PRM.WTYPE_FLOOR;
    head.unknown_type = true;
  else
    head.wtype = idtype;
  end
end

% LLの通常分類は床自重・特殊荷重（内部設計5章）
is_ll_normal = ismember(head.wtype, [PRM.WTYPE_FLOOR, PRM.WTYPE_SPECIAL]);
head.is_unusual = head.wclass == PRM.WCLASS_LL && ~is_ll_normal;

return
end
