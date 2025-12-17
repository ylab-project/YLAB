function createNeighborSearcher(secmgr, idHgap2var, idHgap2sec, ...
  options, idMapper, standardAccessor, constraintValidator, dimension)
%createNeighborSearcher SectionNeighborSearcherインスタンスを作成・初期化
%   createNeighborSearcher(secmgr, idHgap2var, idHgap2sec, options,
%     idMapper, standardAccessor, constraintValidator, dimension) は、
%   SectionNeighborSearcherのインスタンスを作成し、SectionManagerの
%   neighborSearcherプロパティに設定します。
%
%   入力引数:
%     secmgr          - SectionManagerオブジェクト
%     idHgap2var      - 変数IDペア [ngap×2]
%     idHgap2sec      - 断面IDペア [ngap×2]
%     options         - オプション構造体
%                       .reqHgap: 要求梁せい差
%                       .tolHgap: 許容梁せい差
%     idMapper        - IDマッピングオブジェクト
%     standardAccessor - 標準値アクセサオブジェクト
%     constraintValidator - 制約検証オブジェクト
%     dimension       - 全断面のdimension配列
%
%   例:
%     secmgr.createNeighborSearcher(idHgap2var, idHgap2sec, options,
%       idMapper, standardAccessor, constraintValidator, dimension);

% SectionNeighborSearcherインスタンスを作成（dimensionを渡す）
secmgr.neighborSearcher_ = ...
  SectionNeighborSearcher(idHgap2var, idHgap2sec, options, ...
    idMapper, standardAccessor, constraintValidator, dimension);

return
end