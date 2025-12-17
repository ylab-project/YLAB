function C = rsltsfs(rs, Mc, M0, lm, nstiff, Lb, idg2m)
% 弾性横座屈モーメントの修正係数Cの算定
% Cの計算部分をM倉庫用に追加,switchで使用するnstiffはround関数でまとめる

% 計算の準備
nlc = size(rs,3);
nmeg = length(Lb);
C = zeros(nlc*3, nmeg); % (左端,中央,右端)x荷重ケース
for ilc = 1:nlc
  for ig = 1:nmeg
    im = idg2m(ig);
    Ml = -rs(im,5,ilc);
    Mr = rs(im,11,ilc);
    Mcc = -Mc(im,ilc);
    M0c = M0(im, 1);
    Mmax = abs(Ml-(Mr-Ml-4*M0c)^2/(16*M0c));
    Lmax = lm(im)*(4*M0c+Ml-Mr)/(8*M0c);
    if nstiff(ig)<2
      if (0<Lmax && Lmax<lm(im) && max(abs([Ml, Mr]))<Mmax)
        imm = 3*(ilc-1)+1:3*ilc;
        C(imm,ig) = 1.0;
      else
        M1 = absmax(Ml, Mr);
        M2 = absmin(Ml, Mr);
        imm = 3*(ilc-1)+1:3*ilc;
        C(imm,ig) = 1.75-1.05*(M2/M1)+0.3*(M2/M1)^2;
      end
    else
      switch round(nstiff(ig)) %round()で整数に丸める
        case 2
          if (0<Lmax && Lmax<lm(im)/2 && max(abs([Ml, Mcc]))<Mmax)
            M1 = absmax(Mcc, Mr);
            M2 = absmin(Mcc, Mr);
            C(3*(ilc-1)+1, ig) = 1.0;
            C(3*(ilc-1)+2, ig) = 1.0;
            C(3*(ilc-1)+3, ig) = 1.75-1.05*(M2/M1)+0.3*(M2/M1)^2;
          elseif (lm(im)/2<Lmax && Lmax<lm(im)&&max(abs([Mcc, Mr]))<Mmax)
            M1 = absmax(Ml, Mcc);
            M2 = absmin(Ml, Mcc);
            C(3*(ilc-1)+1, ig) = 1.75-1.05*(M2/M1)+0.3*(M2/M1)^2;
            C(3*(ilc-1)+2, ig) = 1.0;
            C(3*(ilc-1)+3, ig) = 1.0;
          else
            M1_1 = absmax(Ml, Mcc);
            M1_2 = absmin(Ml, Mcc);
            M2_1 = absmax(Mcc, Mr);
            M2_2 = absmin(Mcc, Mr);
            C(3*(ilc-1)+1, ig) = 1.75-1.05*(M1_2/M1_1)+0.3*(M1_2/M1_1)^2;
            C(3*(ilc-1)+3, ig) = 1.75-1.05*(M2_2/M2_1)+0.3*(M2_2/M2_1)^2;
            C(3*(ilc-1)+2, ig) = min([C(3*(ilc-1)+1,ig), C(3*(ilc-1)+3,ig)]);
          end
        case 3 %追加 ※ただし, 部材長の1/4, 3/4部分を補剛箇所とする場合を対象
          M_1_4 = Ml+(Mr-Ml-4*M0c)*Lb(ig)/lm(im)*3/4+4*M0c*(Lb(ig)*3/4)^2/lm(im)^2; %Lb×3/4で計算←Lb=lm×1/3として計算されているため
          M_3_4 = Ml+(Mr-Ml-4*M0c)*Lb(ig)*3/lm(im)*3/4+4*M0c*(Lb(ig)*3*3/4)^2/lm(im)^2; %Lb×3/4で計算←Lb=lm×1/3として計算されているため
          if (0<Lmax && Lmax<lm(im)/4 && max(abs([Ml, M_1_4]))<Mmax)
            C(3*(ilc-1)+1, ig) = 1.0;
            M1_1 = absmax(M_1_4, M_3_4);
            M1_2 = absmin(M_1_4, M_3_4);
            M2_1 = absmax(M_3_4, Mr);
            M2_2 = absmin(M_3_4, Mr);
            C(3*(ilc-1)+2, ig) = 1.75-1.05*(M1_2/M1_1)+0.3*(M1_2/M1_1)^2;
            C(3*(ilc-1)+3, ig) = 1.75-1.05*(M2_2/M2_1)+0.3*(M2_2/M2_1)^2;
          elseif (lm(im) / 4 < Lmax && Lmax < lm(im) / 4 * 3 && max(abs([M_1_4, M_3_4])) < Mmax)
            M1_1 = absmax(Ml, M_1_4);
            M1_2 = absmin(Ml, M_1_4);
            M2_1 = absmax(M_3_4, Mr);
            M2_2 = absmin(M_3_4, Mr);
            C(3 * (ilc - 1) + 1, ig) = 1.75 - 1.05 * (M1_2 / M1_1) + 0.3 * (M1_2 / M1_1)^2;
            C(3 * (ilc - 1) + 2, ig) = 1.0;
            C(3 * (ilc - 1) + 3, ig) = 1.75 - 1.05 * (M2_2 / M2_1) + 0.3 * (M2_2 / M2_1)^2;
          elseif (lm(im) / 4 * 3 < Lmax && Lmax < lm(im) && max(abs([M_3_4, Mr])) < Mmax)
            M1_1 = absmax(Ml, M_1_4);
            M1_2 = absmin(Ml, M_1_4);
            M2_1 = absmax(M_1_4, M_3_4);
            M2_2 = absmin(M_1_4, M_3_4);
            C(3 * (ilc - 1) + 1, ig) = 1.75 - 1.05 * (M1_2 / M1_1) + 0.3 * (M1_2 / M1_1)^2;
            C(3 * (ilc - 1) + 2, ig) = 1.75 - 1.05 * (M2_2 / M2_1) + 0.3 * (M2_2 / M2_1)^2;
            C(3 * (ilc - 1) + 3, ig) = 1.0;
          else
            M1_1 = absmax(Ml, M_1_4);
            M1_2 = absmin(Ml, M_1_4);
            M2_1 = absmax(M_1_4, M_3_4);
            M2_2 = absmin(M_1_4, M_3_4);
            M3_1 = absmax(M_3_4, Mr);
            M3_2 = absmin(M_3_4, Mr);
            C(3 * (ilc - 1) + 1, ig) = 1.75 - 1.05 * (M1_2 / M1_1) + 0.3 * (M1_2 / M1_1)^2;
            C(3 * (ilc - 1) + 2, ig) = 1.75 - 1.05 * (M2_2 / M2_1) + 0.3 * (M2_2 / M2_1)^2;                
            C(3 * (ilc - 1) + 3, ig) = 1.75 - 1.05 * (M3_2 / M3_1) + 0.3 * (M3_2 / M3_1)^2;
          end
          if C(3 * (ilc - 1) + 2, ig) >= 2.3 
            C(3 * (ilc - 1) + 2, ig) = 2.3;
          end
          C(3 * (ilc - 1) + 2, ig) = C(3 * (ilc - 1) + 2, ig) / 4; %Lb = lm × 1/3とされていることによる補正 → 許容曲げ応力度算定時の計算プログラムの性質より
        case 4
          M_1_4 = Ml + (Mr - Ml - 4 * M0c) * Lb(ig) / lm(im) + 4 * M0c * Lb(ig)^2 / lm(im)^2;
          M_3_4 = Ml + (Mr - Ml - 4 * M0c) * Lb(ig) * 3 / lm(im) + 4 * M0c * (Lb(ig) * 3)^2 / lm(im)^2;
          if (0 < Lmax && Lmax < lm(im) / 4 && max(abs([Ml, M_1_4])) < Mmax)
            C(3 * (ilc - 1) + 1, ig) = 1.0;
            M1_1 = absmax(M_1_4, Mcc);
            M1_2 = absmin(M_1_4, Mcc);
            M2_1 = absmax(Mcc, M_3_4);
            M2_2 = absmin(Mcc, M_3_4);
            M3_1 = absmax(M_3_4, Mr);
            M3_2 = absmin(M_3_4, Mr);
            C1 = 1.75 - 1.05 * (M1_2 / M1_1) + 0.3 * (M1_2 / M1_1)^2;
            C2 = 1.75 - 1.05 * (M2_2 / M2_1) + 0.3 * (M2_2 / M2_1)^2;
            C(3 * (ilc - 1) + 2, ig) = min([C1, C2]);
            C(3 * (ilc - 1) + 3, ig) = 1.75 - 1.05 * (M3_2 / M3_1) + 0.3 * (M3_2 / M3_1)^2;
          elseif (lm(im) / 4 < Lmax && Lmax < lm(im) / 4 * 3 && (max(abs([M_1_4, Mcc])) < Mmax || max(abs([Mcc, M_3_4])) < Mmax))
            M1_1 = absmax(Ml, M_1_4);
            M1_2 = absmin(Ml, M_1_4);
            M2_1 = absmax(M_3_4, Mr);
            M2_2 = absmin(M_3_4, Mr);
            C(3 * (ilc - 1) + 1, ig) = 1.75 - 1.05 * (M1_2 / M1_1) + 0.3 * (M1_2 / M1_1)^2;
            C(3 * (ilc - 1) + 2, ig) = 1.0;
            C(3 * (ilc - 1) + 3, ig) = 1.75 - 1.05 * (M2_2 / M2_1) + 0.3 * (M2_2 / M2_1)^2;
          elseif (lm(im) / 4 * 3 < Lmax && Lmax < lm(im) && max(abs([M_3_4, Mr])) < Mmax)
            M1_1 = absmax(Ml, M_1_4);
            M1_2 = absmin(Ml, M_1_4);
            M2_1 = absmax(M_1_4, Mcc);
            M2_2 = absmin(M_1_4, Mcc);
            M3_1 = absmax(Mcc, M_3_4);
            M3_2 = absmin(Mcc, M_3_4);
            C1 = 1.75 - 1.05 * (M2_2 / M2_1) + 0.3 * (M2_2 / M2_1)^2;
            C2 = 1.75 - 1.05 * (M3_2 / M3_1) + 0.3 * (M3_2 / M3_1)^2;
            C(3 * (ilc - 1) + 1, ig) = 1.75 - 1.05 * (M1_2 / M1_1) + 0.3 * (M1_2 / M1_1)^2;
            C(3 * (ilc - 1) + 2, ig) = min([C1, C2]);
            C(3 * (ilc - 1) + 3, ig) = 1.0;
          else
            M1_1 = absmax(Ml, M_1_4);
            M1_2 = absmin(Ml, M_1_4);
            M2_1 = absmax(M_1_4, Mcc);
            M2_2 = absmin(M_1_4, Mcc);
            M3_1 = absmax(Mcc, M_3_4);
            M3_2 = absmin(Mcc, M_3_4);
            M4_1 = absmax(M_3_4, Mr);
            M4_2 = absmin(M_3_4, Mr);
            C1 = 1.75 + 1.05 * (M2_2 / M2_1) + 0.3 * (M2_2 / M2_1)^2;
            C2 = 1.75 + 1.05 * (M3_2 / M3_1) + 0.3 * (M3_2 / M3_1)^2;
            C(3 * (ilc - 1) + 1, ig) = 1.75 - 1.05 * (M1_2 / M1_1) + 0.3 * (M1_2 / M1_1)^2;
            C(3 * (ilc - 1) + 2, ig) = min([C1, C2]);
            C(3 * (ilc - 1) + 3, ig) = 1.75 - 1.05 * (M4_2 / M4_1) + 0.3 * (M4_2 / M4_1)^2;
          end
        case 5 %追加
          M_1_5 = Ml + (Mr - Ml - 4 * M0c) * Lb(ig) / lm(im) + 4 * M0c * Lb(ig)^2 / lm(im)^2;
          M_2_5 = Ml + (Mr - Ml - 4 * M0c) * Lb(ig) * 2 / lm(im) + 4 * M0c * (Lb(ig) * 2)^2 / lm(im)^2;
          M_3_5 = Ml + (Mr - Ml - 4 * M0c) * Lb(ig) * 3 / lm(im) + 4 * M0c * (Lb(ig) * 3)^2 / lm(im)^2;
          M_4_5 = Ml + (Mr - Ml - 4 * M0c) * Lb(ig) * 4 / lm(im) + 4 * M0c * (Lb(ig) * 4)^2 / lm(im)^2;
          if (0 < Lmax && Lmax < lm(im) / 5 && max(abs([Ml, M_1_5])) < Mmax)
            M2_1 = absmax(M_2_5, M_3_5);
            M2_2 = absmin(M_2_5, M_3_5);
            M4_1 = absmax(M_4_5, Mr);
            M4_2 = absmin(M_4_5, Mr);
            C(3 * (ilc - 1) + 1, ig) = 1.0;
            C(3 * (ilc - 1) + 2, ig) = 1.75 - 1.05 * (M2_2 / M2_1) + 0.3 * (M2_2 / M2_1)^2;
            C(3 * (ilc - 1) + 3, ig) = 1.75 - 1.05 * (M4_2 / M4_1) + 0.3 * (M4_2 / M4_1)^2;
          elseif (lm(im) / 5 < Lmax && Lmax < lm(im) / 5 * 2 && max(abs([M_1_5, M_2_5])) < Mmax)...
              || (lm(im) / 5 * 3 < Lmax && Lmax < lm(im) / 5 * 4 && max(abs([M_3_5, M_4_5])) < Mmax)
            M1_1 = absmax(Ml, M_1_5);
            M1_2 = absmin(Ml, M_1_5);
            M2_1 = absmax(M_2_5, M_3_5);
            M2_2 = absmin(M_2_5, M_3_5);
            M4_1 = absmax(M_4_5, Mr);
            M4_2 = absmin(M_4_5, Mr);
            C(3 * (ilc - 1) + 1, ig) = 1.75 - 1.05 * (M1_2 / M1_1) + 0.3 * (M1_2 / M1_1)^2;
            C(3 * (ilc - 1) + 2, ig) = 1.75 - 1.05 * (M2_2 / M2_1) + 0.3 * (M2_2 / M2_1)^2;
            C(3 * (ilc - 1) + 3, ig) = 1.75 - 1.05 * (M4_2 / M4_1) + 0.3 * (M4_2 / M4_1)^2;
          elseif (lm(im) / 5 * 2 < Lmax && Lmax < lm(im) / 5 * 3 && max(abs([M_2_5, M_3_5])) < Mmax)
            M1_1 = absmax(Ml, M_1_5);
            M1_2 = absmin(Ml, M_1_5);
            M4_1 = absmax(M_4_5, Mr);
            M4_2 = absmin(M_4_5, Mr);
            C(3 * (ilc - 1) + 1, ig) = 1.75 - 1.05 * (M1_2 / M1_1) + 0.3 * (M1_2 / M1_1)^2;
            C(3 * (ilc - 1) + 2, ig) = 1.0;
            C(3 * (ilc - 1) + 3, ig) = 1.75 - 1.05 * (M4_2 / M4_1) + 0.3 * (M4_2 / M4_1)^2;
          elseif (lm(im) / 5 * 4 < Lmax && Lmax < lm(im) && max(abs([M_4_5, Mr])) < Mmax)
            M1_1 = absmax(Ml, M_1_5);
            M1_2 = absmin(Ml, M_1_5);
            M3_1 = absmax(M_2_5, M_3_5);
            M3_2 = absmin(M_2_5, M_3_5);
            C(3 * (ilc - 1) + 1, ig) = 1.75 - 1.05 * (M1_2 / M1_1) + 0.3 * (M1_2 / M1_1)^2;
            C(3 * (ilc - 1) + 1, ig) = 1.75 - 1.05 * (M3_2 / M3_1) + 0.3 * (M3_2 / M3_1)^2;
            C(3 * (ilc - 1) + 3, ig) = 1.0;
          else
            M1_1 = absmax(Ml, M_1_5);
            M1_2 = absmin(Ml, M_1_5);
            M3_1 = absmax(M_2_5, M_3_5);
            M3_2 = absmin(M_2_5, M_3_5);
            M5_1 = absmax(M_4_5, Mr);
            M5_2 = absmin(M_4_5, Mr);
            C(3 * (ilc - 1) + 1, ig) = 1.75 - 1.05 * (M1_2 / M1_1) + 0.3 * (M1_2 / M1_1)^2;
            C(3 * (ilc - 1) + 2, ig) = 1.75 - 1.05 * (M3_2 / M3_1) + 0.3 * (M3_2 / M3_1)^2;
            C(3 * (ilc - 1) + 3, ig) = 1.75 - 1.05 * (M5_2 / M5_1) + 0.3 * (M5_2 / M5_1)^2;
          end
        case 6 %追加
          M_1_6 = Ml + (Mr - Ml - 4 * M0c) * Lb(ig) / lm(im) + 4 * M0c * Lb(ig)^2 / lm(im)^2;
          M_2_6 = Ml + (Mr - Ml - 4 * M0c) * Lb(ig) * 2 / lm(im) + 4 * M0c * (Lb(ig) * 2)^2 / lm(im)^2;
          M_4_6 = Ml + (Mr - Ml - 4 * M0c) * Lb(ig) * 4 / lm(im) + 4 * M0c * (Lb(ig) * 4)^2 / lm(im)^2;
          M_5_6 = Ml + (Mr - Ml - 4 * M0c) * Lb(ig) * 5 / lm(im) + 4 * M0c * (Lb(ig) * 5)^2 / lm(im)^2;
          if (0 < Lmax && Lmax < lm(im) / 6 && max(abs([Ml, M_1_6])) < Mmax)
            M2_1 = absmax(M_2_6, Mcc);
            M2_2 = absmin(M_2_6, Mcc);
            M3_1 = absmax(Mcc, M_4_6);
            M3_2 = absmin(Mcc, M_4_6);
            M5_1 = absmax(M_5_6, Mr);
            M5_2 = absmin(M_5_6, Mr);
            C(3 * (ilc - 1) + 1, ig) = 1.0;
            C1 = 1.75 + 1.05 * (M2_2 / M2_1) + 0.3 * (M2_2 / M2_1)^2;
            C2 = 1.75 + 1.05 * (M3_2 / M3_1) + 0.3 * (M3_2 / M3_1)^2;
            C(3 * (ilc - 1) + 2, ig) = min([C1, C2]);
            C(3 * (ilc - 1) + 3, ig) = 1.75 - 1.05 * (M5_2 / M5_1) + 0.3 * (M5_2 / M5_1)^2;
          elseif (lm(im) / 6 < Lmax && Lmax < lm(im) / 6 * 2 && max(abs([M_1_6, M_2_6])) < Mmax)...
              || (lm(im) / 6 * 4 < Lmax && Lmax < lm(im) / 6 * 5 && max(abs([M_4_6, M_5_6])) < Mmax)
            M1_1 = absmax(Ml, M_1_6);
            M1_2 = absmin(Ml, M_1_6);
            M2_1 = absmax(M_2_6, Mcc);
            M2_2 = absmin(M_2_6, Mcc);
            M3_1 = absmax(Mcc, M_4_6);
            M3_2 = absmin(Mcc, M_4_6);
            M5_1 = absmax(M_5_6, Mr);
            M5_2 = absmin(M_5_6, Mr);
            C(3 * (ilc - 1) + 1, ig) = 1.75 - 1.05 * (M1_2 / M1_1) + 0.3 * (M1_2 / M1_1)^2;
            C1 = 1.75 + 1.05 * (M2_2 / M2_1) + 0.3 * (M2_2 / M2_1)^2;
            C2 = 1.75 + 1.05 * (M3_2 / M3_1) + 0.3 * (M3_2 / M3_1)^2;
            C(3 * (ilc - 1) + 2, ig) = min([C1, C2]);
            C(3 * (ilc - 1) + 3, ig) = 1.75 - 1.05 * (M5_2 / M5_1) + 0.3 * (M5_2 / M5_1)^2;
          elseif (lm(im) / 6 * 2 < Lmax && Lmax < lm(im) / 6 * 4 && (max(abs([M_2_6, Mcc])) < Mmax || max(abs([Mcc, M_4_6])) < Mmax))
            M1_1 = absmax(Ml, M_1_6);
            M1_2 = absmin(Ml, M_1_6);
            M5_1 = absmax(M_5_6, Mr);
            M5_2 = absmin(M_5_6, Mr);
            C(3 * (ilc - 1) + 1, ig) = 1.75 - 1.05 * (M1_2 / M1_1) + 0.3 * (M1_2 / M1_1)^2;
            C(3 * (ilc - 1) + 2, ig) = 1.0;
            C(3 * (ilc - 1) + 3, ig) = 1.75 - 1.05 * (M5_2 / M5_1) + 0.3 * (M5_2 / M5_1)^2;
          elseif (lm(im) / 6 * 5 < Lmax && Lmax < lm(im) && max(abs([M_5_6, Mr])) < Mmax)
            M1_1 = absmax(Ml, M_1_6);
            M1_2 = absmin(Ml, M_1_6);
            M3_1 = absmax(M_2_6, Mcc);
            M3_2 = absmin(M_2_6, Mcc);
            M4_1 = absmax(Mcc, M_4_6);
            M4_2 = absmin(Mcc, M_4_6);
            C(3 * (ilc - 1) + 1, ig) = 1.75 - 1.05 * (M1_2 / M1_1) + 0.3 * (M1_2 / M1_1)^2;
            C1 = 1.75 + 1.05 * (M3_2 / M3_1) + 0.3 * (M3_2 / M3_1)^2;
            C2 = 1.75 + 1.05 * (M4_2 / M4_1) + 0.3 * (M4_2 / M4_1)^2;
            C(3 * (ilc - 1) + 2, ig) = min([C1, C2]);
            C(3 * (ilc - 1) + 3, ig) = 1.0;
          else
            M1_1 = absmax(Ml, M_1_6);
            M1_2 = absmin(Ml, M_1_6);
            M3_1 = absmax(M_2_6, Mcc);
            M3_2 = absmin(M_2_6, Mcc);
            M4_1 = absmax(Mcc, M_4_6);
            M4_2 = absmin(Mcc, M_4_6);
            M6_1 = absmax(M_5_6, Mr);
            M6_2 = absmin(M_5_6, Mr);
            C(3 * (ilc - 1) + 1, ig) = 1.75 - 1.05 * (M1_2 / M1_1) + 0.3 * (M1_2 / M1_1)^2;
            C1 = 1.75 + 1.05 * (M3_2 / M3_1) + 0.3 * (M3_2 / M3_1)^2;
            C2 = 1.75 + 1.05 * (M4_2 / M4_1) + 0.3 * (M4_2 / M4_1)^2;
            C(3 * (ilc - 1) + 2, ig) = min([C1, C2]);
            C(3 * (ilc - 1) + 3, ig) = 1.75 - 1.05 * (M6_2 / M6_1) + 0.3 * (M6_2 / M6_1)^2;
          end
        otherwise
          % warning('横補剛エラー')
      end
    end
  end
end
C(C>=2.3) = 2.3;

% TODO: とりあえず
C_ = C;
C = zeros(nmeg,3,nlc);
for ilc = 1:nlc
  for ig = 1:nmeg
    id = (ilc-1)*3;
    C(ig,1,ilc) = C_(id+1,ig);
    C(ig,2,ilc) = C_(id+2,ig);
    C(ig,3,ilc) = C_(id+3,ig);
  end
end

return
end