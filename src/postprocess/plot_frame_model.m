function fig = plot_frame_model(com, popts, idxyz)
%plotFrameModel - Plot frame

% 共通定数
% ng = com.ng;
nj = com.nnode;
nm = com.nme;

% 共通配列
scname = [com.section.column.subindex com.section.column.name];
sgname = [com.section.girder.subindex com.section.girder.name];
sbname = com.section.brace.name;
idm2sc = com.member.property.idsecc;
idm2sg = com.member.property.idsecg;
idm2sb = com.member.property.idsecb;
mtype = com.member.property.type;
stype = com.member.property.section_type;
idn2coord = [com.node.idx com.node.idy com.node.idz];
idm2c = com.member.property.idmec;
idm2g = com.member.property.idmeg;
idmewfs = com.member.girder.idmewfs;
Hn = com.design.idvar.wfs.H;
Bn = com.design.idvar.wfs.B;
twn = com.design.idvar.wfs.tw;
tfn = com.design.idvar.wfs.tf;
Dn = com.design.idvar.hss.D;
tn = com.design.idvar.hss.t;
idm2n1 = com.member.property.idnode1;
idm2n2 = com.member.property.idnode2;
x = com.node.x;
y = com.node.y;
z = com.node.z;
node_idz = com.node.idz;
xbl = com.baseline.x;
ybl = com.baseline.y;
zbl = com.baseline.z;
xcoord = com.baseline.x.coord';
ycoord = com.baseline.y.coord';
zcoord = com.baseline.z.coord';

% 描画オプション
if popts.is_plot_proportional_cross_sectional_area
  a = popts.cross_sectional_area;
  amax = max(a);
  line_width = a/amax*popts.line_width;
else
  line_width = popts.line_width*ones(1,nm);
end

% 対象部材・描画サイズ計算
modelsize = [min(x) min(y) min(z)...
  max(x)-min(x) max(y)-min(y) max(z)-min(z)];
switch popts.mode
  case 'PLAN'
    % idj = 1:nj; idj = idj(z==zbl.coord(idxyz));
    idj = 1:nj; idj = idj(node_idz==idxyz);
    zcoord_target = zbl.coord(idxyz);
    z1 = z(idm2n1); z2 = z(idm2n2);
    % 垂直部材：Z座標値で判定（両方向対応）
    ismv = (z2>=zcoord_target & zcoord_target>z1) | ...
           (z1>=zcoord_target & zcoord_target>z2);
    % 水平部材：idz番号で判定（dzがあるため）
    ismh = idn2coord(idm2n2,3)==idxyz & idxyz==idn2coord(idm2n1,3);
    idm = 1:nm; idm = idm(ismv|ismh);
    modelsize = modelsize([4 5]);
  case 'XFRAME'
    idj = 1:nj; idj = idj(y==ybl.coord(idxyz));
    % 梁・柱はAND条件、X方向ブレースのみOR条件
    is_on_frame = (idn2coord(idm2n1,2)==idxyz & idn2coord(idm2n2,2)==idxyz);
    is_x_brace = (mtype==PRM.BRACE & com.member.property.idir==PRM.X);
    is_on_frame = is_on_frame | (is_x_brace & ...
      (idn2coord(idm2n1,2)==idxyz | idn2coord(idm2n2,2)==idxyz));
    idm = 1:nm; idm = idm(is_on_frame);
    modelsize = modelsize([4 6]);
  case 'YFRAME'
    idj = 1:nj; idj = idj(x==xbl.coord(idxyz));
    % 梁・柱はAND条件、Y方向ブレースのみOR条件
    is_on_frame = (idn2coord(idm2n1,1)==idxyz & idn2coord(idm2n2,1)==idxyz);
    is_y_brace = (mtype==PRM.BRACE & com.member.property.idir==PRM.Y);
    is_on_frame = is_on_frame | (is_y_brace & ...
      (idn2coord(idm2n1,1)==idxyz | idn2coord(idm2n2,1)==idxyz));
    idm = 1:nm; idm = idm(is_on_frame);
    modelsize = modelsize([5 6]);
  case '3D'
    idj = 1:nj;
    idm = 1:nm;
    modelsize = max(modelsize)*[1 1];
end
mpsize = max(modelsize.*[1 sqrt(2)]);

% 描画準備
fig = figure('Units', 'centimeters', ...
  ...'Position', [0 0 21 14.8], ...
  'Position', [0 0 21 21], ...
  'visible', popts.is_visible);
cla
hold on
axis equal;
margin = [mpsize*0.12 mpsize*0.03];
xlim([-margin(1) max(x)+margin(2)]);
ylim([-margin(1) max(y)+margin(2)]);
zlim([-margin(1) max(z)+margin(2)]);
plsize = [xlim ylim zlim];
plsize = [plsize(2)-plsize(1) plsize(4)-plsize(3) plsize(6)-plsize(5)];

% daspect([1, 1, 1])
xticks([]); yticks([]); zticks([]);
ax = gca;
switch popts.mode
  case 'PLAN'
    view([0 90])
  case 'XFRAME'
    view([0 0])
  case 'YFRAME'
    view([90 0])
  case '3D'
    % view([150 30])
    view([-30 30])
end
ax.XColor = 'none'; ax.YColor = 'none'; ax.ZColor = 'none';

% 画面ポイントサイズから図面サイズ(mm)への変換係数
ax = gca;
ax.Units = 'points';
axsize = ax.tightPosition;
axsize = axsize(3:4);
switch popts.mode
  case 'PLAN'
    pt2mm = mean([plsize(1)/axsize(1) plsize(2)/axsize(2)]);
  case 'XFRAME'
    pt2mm = mean([plsize(1)/axsize(1) plsize(3)/axsize(2)]);
  case 'YFRAME'
    pt2mm = mean([plsize(2)/axsize(1) plsize(3)/axsize(2)]);
  case '3D'
    pt2mm = 1;
end

% 文字余白の計算
xmargin = 5*pt2mm;
ymargin = 5*pt2mm;
zmargin = 5*pt2mm;
halign = 'left';
valign = 'bottom';

% 節点描画
for i = idj
  dvlabel = ['(' num2str(i) ')'];
  switch popts.mode
    case 'PLAN'
      plot3(x(i), y(i), z(i), 'k.');
      if popts.is_plot_node_number
        text(x(i)+xmargin, y(i)+ymargin, z(i)+zmargin, dvlabel, ...
          'HorizontalAlignment', halign, ...
          'VerticalAlignment', valign);
      end
    case 'XFRAME'
      plot3(x(i), y(i), z(i), 'k.');
      if popts.is_plot_node_number
        text(x(i)+xmargin, y(i)+ymargin, z(i)+zmargin, dvlabel, ...
          'HorizontalAlignment', halign, ...
          'VerticalAlignment', valign);
      end
    case 'YFRAME'
      plot3(x(i), y(i), z(i), 'k.');
      if popts.is_plot_node_number
        text(x(i)+xmargin, y(i)+ymargin, z(i)+zmargin, dvlabel, ...
          'HorizontalAlignment', halign, ...
          'VerticalAlignment', valign);
      end
    case '3D'
      % plot3(x(i), y(i), z(i), 'k.');
  end
end

% 部材描画
halign = 'center';
valign = 'middle';
for i = idm
  s = [x(idm2n1(i)) x(idm2n2(i))];
  t = [y(idm2n1(i)) y(idm2n2(i))];
  u = [z(idm2n1(i)) z(idm2n2(i))];

  % 設計変数番号ラベル
  switch stype(i)
    case PRM.WFS
      ig = idm2g(i);
      iwfs = idmewfs(ig);
      dvlabel = sprintf('(%d,%d,%d,%d)', ...
        Hn(iwfs), Bn(iwfs), twn(iwfs), tfn(iwfs));
    case PRM.HSS
      ic = idm2c(i);
      dvlabel = sprintf('(%d,%d)',Dn(ic), tn(ic));
    otherwise
      dvlabel = '';
  end

  % 断面符号
  switch mtype(i)
    case PRM.GIRDER
      ig = idm2sg(i);
      slabel = sprintf('%s%s', sgname{ig,1}, sgname{ig,2});
    case PRM.COLUMN
      ic = idm2sc(i);
      slabel = sprintf('%s%s', scname{ic,1}, scname{ic,2});
    case PRM.BRACE
      ib = idm2sb(i);
      slabel = sprintf('%s%s', sbname{ib});
  end

  switch popts.mode
    case 'PLAN'
      % 部材
      plot3(s, t, u, '-k', 'LineWidth', line_width(i))

      % 位置調整
      switch mtype(i)
        case PRM.GIRDER
          xmargin_ = 0;
          ymargin_ = 0;
          zmargin_ = 10;
          halign_ = 'center';
          valign_ = 'middle';
          color_ = 'w';
        case PRM.BRACE
          xmargin_ = 0;
          ymargin_ = 3*ymargin;
          zmargin_ = 10;
          halign_ = 'center';
          valign_ = 'middle';
          color_ = 'w';
        case PRM.COLUMN
          xmargin_ = xmargin;
          ymargin_ = ymargin;
          zmargin_ = 10;
          halign_ = 'left';
          valign_ = 'bottom';
          color_ = 'none';
          plot3(x(idm2n1(i)), y(idm2n1(i)), max(z([idm2n1(i) idm2n2(i)])+10), ...
            'ks', 'LineWidth', line_width(i), 'MarkerFaceColor','w');
      end

      % 断面符号
      if popts.is_plot_section_name
        text(mean(s)+xmargin_, mean(t)+ymargin_, max(u)+zmargin_, slabel ...
          ,'BackgroundColor', color_ ...
          ,'HorizontalAlignment', halign_ ...
          ,'VerticalAlignment', valign_);
      end

      % 部材番号
      if popts.is_plot_member_number
        text(mean(s)+xmargin_, mean(t)+ymargin_, max(u)+zmargin_, num2str(i) ...
          ,'BackgroundColor', color_ ...
          ,'HorizontalAlignment', halign_ ...
          ,'VerticalAlignment', valign_);
      end

      % 設計変数番号
      if popts.is_plot_design_varable_number
        text(mean(s)+xmargin_, mean(t)+ymargin_, max(u)+zmargin_, dvlabel ...
          ,'BackgroundColor', color_ ...
          ,'HorizontalAlignment', halign_ ...
          ,'VerticalAlignment', valign_);
      end

    case 'XFRAME'
      % 部材
      plot3(s, t, u, '-k', 'LineWidth', line_width(i))

      % 断面符号
      if popts.is_plot_section_name
        text(mean(s), min(t)-10, mean(u), slabel ...
          ,'BackgroundColor', 'w' ...
          ,'HorizontalAlignment', halign ...
          ,'VerticalAlignment', valign);
      end

      % 部材番号
      if popts.is_plot_member_number
        text(mean(s), mean(u), num2str(i) ...
          ,'BackgroundColor', 'w' ...
          ,'HorizontalAlignment', halign ...
          ,'VerticalAlignment', valign);
      end

      % 設計変数番号
      if popts.is_plot_design_varable_number
        text(mean(s), mean(u), dvlabel ...
          ,'BackgroundColor', 'w' ...
          ,'HorizontalAlignment', halign ...
          ,'VerticalAlignment', valign);
      end

    case 'YFRAME'
      % 部材
      plot3(s, t, u, '-k', 'LineWidth', line_width(i))

      % 断面符号
      if popts.is_plot_section_name
        text(max(s)+10, mean(t), mean(u), slabel ...
          ,'BackgroundColor', 'w' ...
          ,'HorizontalAlignment', halign ...
          ,'VerticalAlignment', valign);
      end

      % 部材番号
      if popts.is_plot_member_number
        text(mean(t), mean(u), num2str(i) ...
          ,'BackgroundColor', 'w' ...
          ,'HorizontalAlignment', halign ...
          ,'VerticalAlignment', valign);
      end

    case '3D'
      % 部材
      plot3(s, t, u, '-k', 'LineWidth', line_width(i))
  end
end

% --- 寸法線描画 ---
if popts.is_plot_dimension_line
  xlabel = xbl.name;
  ylabel = ybl.name;
  zlabel = zbl.name;
  switch popts.mode
    case 'PLAN'
      for i=1:length(xcoord)-1
        if xbl.isdummy(i) || xbl.isdummy(i+1)
          continue
        end
        text(mean(xcoord([i i+1])), -28*pt2mm, 0, ...
          sprintf('%.0f',xcoord(i+1)-xcoord(i)), ...
          'HorizontalAlignment', 'center', ...
          'VerticalAlignment', 'bottom');
      end
      for i=1:length(xcoord)
        if ~xbl.isdummy(i)
          text(xcoord(i), -33*pt2mm, 0, ...
            xlabel{i}, ...
            'HorizontalAlignment', 'center', ...
            'VerticalAlignment', 'top');
        end
        plot(xcoord([i i]), pt2mm*[-30 -20], '-k')
      end
      for i=1:length(ycoord)-1
        if ybl.isdummy(i) || ybl.isdummy(i+1)
          continue
        end
        text(-28*pt2mm, mean(ycoord([i i+1])), 0, ...
          sprintf('%.0f',ycoord(i+1)-ycoord(i)), ...
          'Rotation', 90, ...
          'HorizontalAlignment', 'center', ...
          'VerticalAlignment', 'top');
      end
      for i=1:length(ycoord)
        if ~ybl.isdummy(i)
          text(-33*pt2mm, ycoord(i), 0, ...
            ylabel{i}, ...
            'Rotation', 90, ...
            'HorizontalAlignment', 'center', ...
            'VerticalAlignment', 'bottom');
        end
        plot3(pt2mm*[-30 -20], ycoord([i i]), [0 0], '-k')
      end
      plot3(xcoord([1 end]), pt2mm*[-30 -30], [0 0], '-k');
      plot3(pt2mm*[-30 -30], ycoord([1 end]), [0 0], '-k');

    case 'XFRAME'
      for i=1:length(xcoord)-1
        if xbl.isdummy(i) || xbl.isdummy(i+1)
          continue
        end
        text(mean(xcoord([i i+1])), 0, -28*pt2mm, ...
          sprintf('%.0f',xcoord(i+1)-xcoord(i)), ...
          'HorizontalAlignment', 'center', ...
          'VerticalAlignment', 'bottom');
      end
      for i=1:length(xcoord)
        if ~xbl.isdummy(i)
          text(xcoord(i), 0, -33*pt2mm, ...
            xlabel{i}, ...
            'HorizontalAlignment', 'center', ...
            'VerticalAlignment', 'top');
        end
        plot3(xcoord([i i]), [0 0], pt2mm*[-30 -20], '-k')
      end
      for i=1:length(zcoord)-1
        if zbl.isdummy(i) || zbl.isdummy(i+1)
          continue
        end
        text(-28*pt2mm, 0, mean(zcoord([i i+1])), ...
          sprintf('%.0f',zcoord(i+1)-zcoord(i)), ...
          'Rotation', 90, ...
          ...'HorizontalAlignment', 'right', ...
          'HorizontalAlignment', 'center', ...
          'VerticalAlignment', 'top');
      end
      for i=1:length(zcoord)
        if ~zbl.isdummy(i)
          % text(-33*pt2mm, 0, zcoord(i), ...
          text(-40*pt2mm, 0, zcoord(i), ...
            zlabel{i}, ...
            ...'Rotation', 90, ...
            'HorizontalAlignment', 'right', ...
            'VerticalAlignment', 'middle');
        end
        plot3(pt2mm*[-30 -20], [0 0], zcoord([i i]), '-k')
      end
      plot3(xcoord([1 end]), [0 0], pt2mm*[-30 -30], '-k');
      plot3(pt2mm*[-30 -30], [0 0], zcoord([1 end]), '-k');

    case 'YFRAME'
      for i=1:length(ycoord)-1
        if ybl.isdummy(i) || ybl.isdummy(i+1)
          continue
        end
        text(0, mean(ycoord([i i+1])), -28*pt2mm, ...
          sprintf('%.0f',ycoord(i+1)-ycoord(i)), ...
          'HorizontalAlignment', 'center', ...
          'VerticalAlignment', 'bottom');
      end
      for i=1:length(ycoord)
        if ~ybl.isdummy(i)
          text(0, ycoord(i), -33*pt2mm, ...
            ylabel{i}, ...
            'HorizontalAlignment', 'center', ...
            'VerticalAlignment', 'top');
        end
        plot3([0 0], ycoord([i i]), pt2mm*[-30 -20], '-k')
      end
      for i=1:length(zcoord)-1
        if zbl.isdummy(i) || zbl.isdummy(i+1)
          continue
        end
        text(0, -28*pt2mm, mean(zcoord([i i+1])), ...
          sprintf('%.0f',zcoord(i+1)-zcoord(i)), ...
          'Rotation', 90, ...
          'HorizontalAlignment', 'center', ...
          'VerticalAlignment', 'top');
      end
      for i=1:length(zcoord)
        if ~zbl.isdummy(i)
          % text(0, -33*pt2mm, zcoord(i), ...
          text(0, -40*pt2mm, zcoord(i), ...
            zlabel{i}, ...
            ...'Rotation', 90, ...
            'HorizontalAlignment', 'right', ...
            'VerticalAlignment', 'bottom');
        end
        plot3([0 0], pt2mm*[-30 -20], zcoord([i i]), '-k')
      end
      plot3([0 0], ycoord([1 end]), pt2mm*[-30 -30], '-k');
      plot3([0 0], pt2mm*[-30 -30], zcoord([1 end]), '-k');
  end

  % switch popts.mode
  %   case 'PLAN'
  %     for i=1:length(ycoord)-1
  %       text(-28*pt2mm, mean(ycoord([i i+1])), 0, ...
  %         num2str(ycoord(i+1)-ycoord2(i)), ...
  %         'Rotation', 90, ...
  %         'HorizontalAlignment', 'center', ...
  %         'VerticalAlignment', 'top');
  %     end
  %     for i=1:length(ycoord)
  %       text(-33*pt2mm, ycoord(i), ybl.name{i} ...
  %         ,'Rotation', 90 ...
  %         ,'HorizontalAlignment', 'center' ...
  %         ,'VerticalAlignment', 'bottom');
  %       plot(pt2mm*[-30 -20], bl2([i i]), '-k')
  %     end
  %     plot(bl1([1 end]), pt2mm*[-30 -30], '-k');
  %     plot(pt2mm*[-30 -30], bl2([1 end]), '-k');
  %   case 'XFRAME'
  % end
  % for i=1:length(bl1)-1
  %   text(bl1m(i), bl2, bl3, num2str(bl1(i+1)-bl1(i)) ...
  %     ,'HorizontalAlignment', 'center' ...
  %     ,'VerticalAlignment', 'bottom');
  % end
  % for i=1:length(bl1)
  %   text(bl1(i), bl2(i), bl3(i)-5*pt2mm, bllabel{i} ...
  %     ,'HorizontalAlignment', 'center' ...
  %     ,'VerticalAlignment', 'top');
  %   plot(bl11(i,:), bl22(i,:), bl33(i,:), '-k')
  % end
  % for i=1:length(bl2)-1
  %   text(-28*pt2mm, mean(bl2([i i+1])), num2str(bl2(i+1)-bl2(i)) ...
  %     ,'Rotation', 90 ...
  %     ,'HorizontalAlignment', 'center' ...
  %     ,'VerticalAlignment', 'top');
  % end
  % for i=1:length(bl2)
  %   text(-33*pt2mm, bl2(i), bl2label{i} ...
  %     ,'Rotation', 90 ...
  %     ,'HorizontalAlignment', 'center' ...
  %     ,'VerticalAlignment', 'bottom');
  %   plot(pt2mm*[-30 -20], bl2([i i]), '-k')
  % end
  % plot(bl1([1 end]), pt2mm*[-30 -30], '-k');
  % plot(pt2mm*[-30 -30], bl2([1 end]), '-k');
end
hold off
return
end
