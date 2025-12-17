function [A, Asy, Asz, Iy, Iz, Zy, Zz, Zyf, Zpy, Zpz, JJ, Aw] = ...
  datasf(H, B, tw, tf, D, t, stype, rg, rc, scallop)

% TODO 部材の数ではなく断面の数にする
nsec  = length(stype);
% nwfs  = sum((stype==PRM.WFS));
% nhss  = sum((stype==PRM.HSS));
% if nargin<8
%   compEffect = zeros(nwfs,1);
% end
if nargin<9
  %rc = t * 3.5; % BCP:3.5t,
  %rc = t * 2.5; % BCR:2.5t
  %rc = t * 2.0; % STKR:2.0t
  rc = 0;
  rg = 0;
end
if nargin<11
  scallop = 0;
end
%
% H = reshapeRowVector(H);
% B = reshapeRowVector(B);
% tw = reshapeRowVector(tw);
% tf = reshapeRowVector(tf);
% D = reshapeRowVector(D);
% t = reshapeRowVector(t);
% rc = reshapeRowVector(rc);
% rg = reshapeRowVector(rg);
H = H(:)';
B = B(:)';
tw = tw(:)';
tf = tf(:)';
D = D(:)';
t = t(:)';
rc = rc(:)';
rg = rg(:);
%
A   = zeros(nsec,1); % cross-sectional area
Asy = zeros(nsec,1); % area for shear (the strong axis)
Asz = zeros(nsec,1); % area for shear (the weak axis)
Iyo = zeros(nsec,1); % original second moment of area (the strong axis)
Iy  = zeros(nsec,1); % modified second moment of area (the strong axis)
Iz  = zeros(nsec,1); % second moment of area (the weak axis)
Zy  = zeros(nsec,1); % section modulus (the strong axis)
Zz  = zeros(nsec,1); % section modulus (the weak axis)
Zyf = zeros(nsec,1); % section modulus for calculating allowable bending stress
Zpy = zeros(nsec,1); % plastic section modulus (the strong axis)
Zpz = zeros(nsec,1); % plastic section modulus (the weak axis)
JJ  = zeros(nsec,1);
Aw  = zeros(nsec,1); % area for shear (for end section calculation)

%---
% Column
%---
rr = rc-t;
dd = D-2*t;
DmR = D/2-rc;
dmr = dd/2-rr;
A_ = (D-2*rc).*t*4 + pi.*(rc.^2-rr.^2);
Asy_ = A_/2;
Asz_ = Asy_;
Iy_ = (pi/8*(rc.^4-rr.^4) ...
  +4/3*(rc.^3.*DmR-rr.^3.*dmr) ...
  +pi/2*(rc.^2.*DmR.^2-rr.^2.*dmr.^2) ...
  +2/3*(rc.*DmR.^3-rr.*dmr.^3))*2 ...
  +DmR.*(D.^3-dd.^3)/6;
% aiy(i) = (D^4-(D-2*t)^4)/12;
% Iyo_ = Iy_;
Iz_ = Iy_;
Zy_ = Iy_./(D/2);
Zz_ = Zy_;
Zpy_ = (D-2*rc).*t.*(D-t) ...
  + 1/2*t.*(D-2*rc).^2 ...
  + pi*t.*(2*rc-t).*(D/2-rc+4*(rc.^3-(rc-t).^3) ...
  ./((3*pi)*(rc.^2-(rc-t).^2)));
Zpz_ = Zpy_;
AA = D.^2+pi*rc.^2-t.*(2*D+pi*rc-4*rc) ...
  +pi/4*t.^2-4*rc.^2;
LL = 4*D-8*rc+2*pi*rc-pi*t;
JJ_ = 4*AA.^2.*t./LL;
A(stype==PRM.COLUMN) = A_;
Asy(stype==PRM.COLUMN) = Asy_;
Asz(stype==PRM.COLUMN) = Asz_;
Iyo(stype==PRM.COLUMN) = Iyo_;
Iy(stype==PRM.COLUMN) = Iy_;
Iz(stype==PRM.COLUMN) = Iz_;
Zy(stype==PRM.COLUMN) = Zy_;
Zz(stype==PRM.COLUMN) = Zz_;
Zpy(stype==PRM.COLUMN) = Zpy_;
Zpz(stype==PRM.COLUMN) = Zpz_;
JJ(stype==PRM.COLUMN) = JJ_;
Aw(stype==PRM.COLUMN) = Asy_;

%---
% Girder
%---
rd = (1-2/3/(4-pi))*rg;
rA = (1-pi/4)*rg.^2;
rI = (1/3-pi/16-1/9/(4-pi))*rg.^4;
A_ = H.*B-(B-tw).*(H-2*tf)+4*rA;
Asy_ = (H-2*tf).*tw;
Asz_ = B.*tf.*2;
Aw_ = (H-2*tf-2*scallop).*tw;
%aiy_ = (B .* H.^3 - (B - tw) .* (H - 2 * tf).^3)/12;
%aiz_ = (tf * 2 .* B.^3 + (H - 2 * tf) .* tw.^3) / 12;
If1 = B.*tf.^3/12 + B.*tf.*(H-tf).^2/4;
Iw1 = tw.*(H-2*tf).^3/12;
Ir1 = rI+rA.*((H-2*tf)/2-rd).^2;
Iy_ = 2*If1 + Iw1 + 4*Ir1;
If2 = tf.*B.^3/12;
Iw2 = (H-2*tf).*tw.^3/12;
Ir2 = rI+rA.*(tw/2+rd).^2;
Iz_ = 2*If2 + Iw2 + 4*Ir2;
Zy_ = Iy_./(H/2);
Zz_ = Iz_./(B/2);
Zyf_ = B.*(H.^3-(H-2*tf).^3)./(6*H);
% zyf(i) = aiy(i)/(H/2);
%zpy_ = B .* tf .* (H - tf) + (H - 2 * tf).^2 .* tw / 4;
%zpz_ = tf .* B.^2/2 + (H - 2 * tf) .* tw.^2/4;
Zpy_ = B.*tf.*(H-tf) + 1/4*tw.*(H-2*tf).^2 + 2*rA.*(H-2*tf-2*rd);
Zpz_ = 1/2*B.^2.*tf + 1/4*(H-2*tf).*tw.^2 + 2*rA.*(tw+2*rd);
JJ_ = ((B .* tf.^3) * 2 + ((H - 2 * tf) .* tw.^3)) / 3;

% TODO とりあえず
rrr = ones(1,nwfs);
rrr(compEffect==1) = 1.3;
rrr(compEffect==2) = 1.5;

Iyo_ = Iy_;
Iy_ = Iy_.*rrr;

A(stype==PRM.GIRDER) = A_;
Asy(stype==PRM.GIRDER) = Asy_;
Asz(stype==PRM.GIRDER) = Asz_;
% Iyo(type==PRM.GIRDER) = Iyo_;
Iy(stype==PRM.GIRDER) = Iy_;
Iz(stype==PRM.GIRDER) = Iz_;
Zy(stype==PRM.GIRDER) = Zy_;
Zz(stype==PRM.GIRDER) = Zz_;
Zyf(stype==PRM.GIRDER) = Zyf_;
Zpy(stype==PRM.GIRDER) = Zpy_;
Zpz(stype==PRM.GIRDER) = Zpz_;
JJ(stype==PRM.GIRDER) = JJ_;
Aw(stype==PRM.GIRDER) = Aw_;
end

