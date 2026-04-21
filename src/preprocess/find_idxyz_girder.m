function [idx, idy, idz, idir, idznominal, iorigin] = ...
  find_idxyz_girder(story_name, frame_name, coord_name, baseline)
%find_idxyz_girder - 梁の通り・階ID特定（「全/ALL」指定の展開対応）
%
%   [idx, idy, idz, idir, idznominal, iorigin] = find_idxyz_girder( ...
%     story_name, frame_name, coord_name, baseline) は、入力の層名・
%   フレーム名・軸名を baseline 上のIDレンジ [1×2] に変換する。
%   フレームが「全/ALL」のときは X/Y 両方向に 2 行展開（最大 2n 行
%   出力）し、idir で X 方向 / Y 方向を区別する。
%
%   入力引数:
%     story_name - 層名 [n×m] cell（m=1:単一, m=2:始端終端）
%     frame_name - フレーム名 [n×m] cell
%     coord_name - 軸名 [n×2] cell（始端・終端）
%     baseline   - 通り情報構造体（.x.name, .y.name, .z.name,
%                  .z.idnominal 等）
%
%   出力引数:
%     idx        - X軸IDレンジ [io×2]
%     idy        - Y軸IDレンジ [io×2]
%     idz        - 層Z-IDレンジ [io×2]
%     idir       - 梁方向 [io×1]（PRM.X / PRM.Y）
%     idznominal - ダミー層を実層に解決した名目層ID [io×2]
%     iorigin    - 出力 io 行目に対応する元入力行 i [io×1]
%                  （フレーム「全」展開で同じ i が 2 回現れる）
%
%   備考:
%     - m = size(frame_name,2):
%       m==1: フレーム・層は単一、軸は始端終端指定
%       m==2: フレーム・層・軸すべて始端終端指定

% 定数
n = size(frame_name,1);
m = size(frame_name,2);

nblx = size(baseline.x,1);
nbly = size(baseline.y,1);
nblz = size(baseline.z,1);

% 出力バッファ（フレーム「全」で 1→2 行展開のため最大 2n 行）
idir = zeros(n*2,1);
idx = zeros(n*2,2); iddx = 1:nblx;
idy = zeros(n*2,2); iddy = 1:nbly;
idz = zeros(n*2,2); iddz = 1:nblz;
iorigin = zeros(n*2,1);
% xylist: X/Y フレーム名の連結。前半 nblx 個が X、後半 nbly 個が Y。
% 「idxy<=nblx なら X フレーム」と単純判定するための仕掛け。
xlist = baseline.x.name;
ylist = baseline.y.name;
zlist = baseline.z.name;
xylist = [xlist(:)' ylist(:)'];

io = 0;
if m==1
  for i=1:n
    if is_all_token(frame_name{i,1})
      [io, idir, idx, idy, idz, iorigin] = expand_all_frame( ...
        io, idir, idx, idy, idz, iorigin, i, story_name(i,:), ...
        coord_name(i,:), m, iddx, iddy, iddz, xlist, ylist, zlist, ...
        nblx, nbly, nblz);
      continue
    end
    io = io+1;
    iorigin(io) = i;
    idxy = find(matches(xylist, frame_name{i}), 1);
    if isempty(idxy)
      continue
    end
    if idxy<=nblx
      idir(io) = PRM.Y;
      idx(io,:) = idxy;
      idy(io,1) = iddy(matches(ylist, coord_name{i,1}));
      idy(io,2) = iddy(matches(ylist, coord_name{i,2}));
    else
      idir(io) = PRM.X;
      idy(io,:) = idxy-nblx;
      idx(io,1) = iddx(matches(xlist, coord_name{i,1}));
      idx(io,2) = iddx(matches(xlist, coord_name{i,2}));
    end
    idz(io,:) = resolve_story(story_name(i,:), m, iddz, zlist, nblz);
  end
else
  for i=1:n
    if is_all_token(frame_name{i,1})
      [io, idir, idx, idy, idz, iorigin] = expand_all_frame( ...
        io, idir, idx, idy, idz, iorigin, i, story_name(i,:), ...
        coord_name(i,:), m, iddx, iddy, iddz, xlist, ylist, zlist, ...
        nblx, nbly, nblz);
      continue
    end
    io = io+1;
    iorigin(io) = i;
    idxy = find(matches(xylist, frame_name{i,1}), 1);
    if isempty(idxy)
      continue
    end
    if idxy<=nblx
      idir(io) = PRM.Y;
      idx(io,1) = iddx(matches(xlist, frame_name{i,1}));
      idx(io,2) = iddx(matches(xlist, frame_name{i,2}));
      idy(io,1) = iddy(matches(ylist, coord_name{i,1}));
      idy(io,2) = iddy(matches(ylist, coord_name{i,2}));
    else
      idir(io) = PRM.X;
      idy(io,1) = iddy(matches(ylist, frame_name{i,1}));
      idy(io,2) = iddy(matches(ylist, frame_name{i,2}));
      idx(io,1) = iddx(matches(xlist, coord_name{i,1}));
      idx(io,2) = iddx(matches(xlist, coord_name{i,2}));
    end
    idz(io,:) = resolve_story(story_name(i,:), m, iddz, zlist, nblz);
  end
end

% trim
idx = idx(1:io,:);
idy = idy(1:io,:);
idz = idz(1:io,:);
idir = idir(1:io);
iorigin = iorigin(1:io);

% ダミー層 → 名目層
if nargout>=5
  idznominal = baseline.z.idnominal(idz);
end
return
end


function iz = resolve_story(srow, m, iddz, zlist, nblz)
%resolve_story - 層レンジ解決（「全/ALL」は [1,nblz]）
%
%   iz = resolve_story(srow, m, iddz, zlist, nblz) は、層名 1 行
%   ぶんを baseline.z 上のIDレンジ [1×2] に解決する。'全'/'ALL'
%   は [1,nblz]、それ以外は zlist との一致から ID を引く。
%
%   入力引数:
%     srow  - 層名 1 行 [1×m] cell（m=1:単一, m=2:始端終端）
%     m     - srow の列数（1 または 2）
%     iddz  - 1:nblz の連番ベクトル
%     zlist - 層名リスト [nblz×1] cell
%     nblz  - 層数
%
%   出力引数:
%     iz - 層Z-IDレンジ [1×2]
if is_all_token(srow{1})
  iz = [1, nblz];
elseif m==1
  iz = iddz(matches(zlist, srow{1}));
else
  iz = [iddz(matches(zlist, srow{1})), iddz(matches(zlist, srow{2}))];
end
return
end


function ic = resolve_coord(crow, iddc, clist, nblc)
%resolve_coord - 軸レンジ解決（「全/ALL」は [1,nblc]）
%
%   ic = resolve_coord(crow, iddc, clist, nblc) は、軸名 1 行
%   ぶん（始端・終端）を baseline 上のIDレンジ [1×2] に解決する。
%   始端が '全'/'ALL' なら [1,nblc]、それ以外は clist との一致
%   から ID を引く。
%
%   入力引数:
%     crow  - 軸名 1 行 [1×2] cell（始端・終端）
%     iddc  - 1:nblc の連番ベクトル
%     clist - 軸名リスト [nblc×1] cell
%     nblc  - 軸数
%
%   出力引数:
%     ic - 軸IDレンジ [1×2]
if is_all_token(crow{1})
  ic = [1, nblc];
else
  ic = [iddc(matches(clist, crow{1})), iddc(matches(clist, crow{2}))];
end
return
end


function [io, idir, idx, idy, idz, iorigin] = expand_all_frame( ...
  io, idir, idx, idy, idz, iorigin, i, story_row, coord_row, m, ...
  iddx, iddy, iddz, xlist, ylist, zlist, nblx, nbly, nblz)
%expand_all_frame - フレーム「全/ALL」指定をX/Y方向2行に展開
%
%   [io, idir, idx, idy, idz, iorigin] = expand_all_frame(...) は、
%   フレーム「全」指定の 1 入力行を出力バッファに 2 行展開する
%   （1行目: Y方向全域、2行目: X方向全域）。io は出力バッファの
%   現在位置で、展開後に 2 増やして返す。
%
%   入力引数:
%     io        - 出力バッファ現在位置（更新前）
%     idir/idx/idy/idz/iorigin - 出力バッファ（更新前）
%     i         - 元入力行の添字
%     story_row - 層名 1 行 [1×m] cell
%     coord_row - 軸名 1 行 [1×2] cell
%     m, iddx/iddy/iddz, xlist/ylist/zlist, nblx/nbly/nblz
%               - find_idxyz_girder の内部変数（解決用）
%
%   出力引数:
%     io/idir/idx/idy/idz/iorigin - 2 行追加後のバッファ
iz = resolve_story(story_row, m, iddz, zlist, nblz);
io = io + 1;
idir(io) = PRM.Y;
idx(io,:) = [1, nblx];
idz(io,:) = iz;
idy(io,:) = resolve_coord(coord_row, iddy, ylist, nbly);
iorigin(io) = i;
io = io + 1;
idir(io) = PRM.X;
idy(io,:) = [1, nbly];
idz(io,:) = iz;
idx(io,:) = resolve_coord(coord_row, iddx, xlist, nblx);
iorigin(io) = i;

return
end
