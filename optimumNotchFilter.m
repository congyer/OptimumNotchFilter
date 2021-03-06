%实现最佳陷波滤波器
%{
具体步骤：
1、读取图像
2、进行快速傅里叶变换
3、将频域图像居中
4、生成小尺寸的 Butterworth 低通滤波器
5、通过观察频域图像，确定需要排除的频率成分，记下其坐标，制作陷波带通模版
6、把所得的陷波带通模版用于最佳滤波器的实现

其他：
加入了直接对频域图像进行陷波滤波的对比
%}
clear;clc;
tic;                                        %计时

%% 读取图像
img = imread('data\origin1.png');           %读取图像
if size(img, 3) == 3                        %若为彩色图，转为灰度图
    img = rgb2gray(img);
end
% figure('Name', '原图');                     %显示原图
% imshow(img);

%% 快速傅里叶变换
IMG = fft2(img);                            %进行快速傅里叶变换

%% 频域图像居中
Guv = fftshift(IMG);                        %对傅里叶变换的结果进行居中处理
% figure;
% mesh(abs(Guv));
% figure('Name', '原图平移后傅里叶谱');        %显示原图平移后傅里叶谱
% imshow(log(abs(Guv) + 1), []);
%输出平移后的傅里叶谱
GvuOut = log(abs(Guv) + 1);                 %灰度压缩
GvuOut = GvuOut * 255 / max(GvuOut(:));     %灰度拉伸至0-255
GvuOut = uint8(GvuOut);                     %输出需要uint8类型
imwrite(GvuOut, 'data\origin1FT.png');      %输出

%% 生成小尺寸 Butterworth 低通滤波器
lengthOfSide = 35;                                      %滤波器边长
halfLengthOfSideCeil = ceil(lengthOfSide / 2);          %半边长
halfLengthOfSideFloor = floor(lengthOfSide / 2);        %半边长
Duv = zeros(lengthOfSide);                              %用于存储每一点到滤波器中心的距离
for i = 1 : lengthOfSide                                %遍历Duv，计算Duv中每一点到中心的距离
    for j = 1 : lengthOfSide
        Duv(i, j) = norm([i - halfLengthOfSideCeil, j - halfLengthOfSideCeil]);
    end
end

D0 = floor(halfLengthOfSideCeil / 3);                   %D0为滤波器参数，表示截止频率
n = 2;                                                  %n为滤波器参数，表示滤波器阶数
Huv = zeros(lengthOfSide);                              %存储滤波器的矩阵
for i = 1 : lengthOfSide                                %遍历，计算得到滤波器每一点的值
    for j = 1 : lengthOfSide
        Huv(i, j) = 1 / (1 + (Duv(i, j) / D0) .^ (2 * n));
    end
end
% figure;
% mesh(Huv);
% figure('Name', '小尺寸 Butterworth 低通滤波器');        %显示小尺寸 Butterworth 低通滤波器
% imshow(Huv, []);

%% 制作陷波带通模版
HNPuv = zeros(size(Guv, 1) + 2 * halfLengthOfSideFloor);        %存储陷波带通模版，需要padding以放置在边缘的小尺寸模版，最后结束时再裁剪

%根据傅里叶图像放置的小尺寸滤波器的坐标，为两列矩阵，第一列表示行数，第二列表示列数。由于对称性，仅包含图像下半部分的点
POINTS = [370 317; 371 345; 363 368; 308 360; 363 79; 370 28; 316 20; 370 220; ...
    198 288; 220 295; 211 60; ...
    208 11; 209 15; 210 57; 211 61; 213 106; 226 135; 215 153; 250 143; 209 141; 274 149; 210 152; 220 152; 215 152; ...
    256 154; 238 159; 278 160; 296 155; 319 161; 217 201; 233 193; 233 197; 216 201; 262 213; 232 232; 214 237; 253 237; ...
    196 242; 219 248; 237 243; 259 249; 276 245; 300 250; 282 255; 241 253; 242 278; 220 293; 222 297; 244 303; 266 308; ...
    198 288; 198 290; 198 334; 200 338; 198 375; 202 382; 228 52; 234 66; 246 49; 251 59; 269 54; 274 66; 235 111; ...
    283 90; 314 73; 366 76; 370 81; 384 115; 349 119; 348 126; 300 167; 316 175; 380 185; 375 178; 374 171; 381 209; ...
    253 106; 258 118; 251 191; 311 365; 217 329; 221 340; 257 331; 263 343; 312 306; 234 324; 241 340; ...
    207 120; 216 117; 356 296; 227 281; 238 291; 284 219; 290 224; 200 253; 313 183];

%根据傅里叶图像沿水平方向连续放置的小尺寸滤波器，为三列矩阵，第一列表示行数，第二、三列分别表示起始、终止的列数
HLINES = [196 135 159; 196 275 304];
%根据傅里叶图像沿竖直方向连续放置的小尺寸滤波器，为三列矩阵，第一列表示列数，第二、三列分别表示起始、终止的行数
VLINES = [287 195 220; 290 195 216];
% HLINES = [370 307 327; 363 361 375; 363 73 85; 370 11 45; 194 1 170; 194 218 386];
% VLINES = [184 218 386; 208 218 386; 193 218 386; 195 218 386];

%将连续放置的小尺寸滤波器加入到小尺寸滤波器的坐标矩阵中
for i = 1 : size(HLINES, 1)                                             %遍历需要放置的线段
    tempR = repmat(HLINES(i, 1), HLINES(i, 3) -  HLINES(i, 2) + 1, 1);  %根据线段跨过的像素数，生成相应数量的重复的行号
    tempC = HLINES(i, 2) :  HLINES(i, 3);                               %生成连续的列号
    tempC = tempC';
    temp = [tempR, tempC];                                              %合并两个矩阵
    POINTS = [POINTS; temp];                                            %合并至小尺寸滤波器的坐标矩阵中
end
for i = 1 : size(VLINES, 1)
    tempC = repmat(VLINES(i, 1), VLINES(i, 3) -  VLINES(i, 2) + 1, 1);
    tempR = VLINES(i, 2) :  VLINES(i, 3);
    tempR = tempR';
    temp = [tempR, tempC];
    POINTS = [POINTS; temp];
end

%将小尺寸滤波器放入坐标指示的位置
for i = 1 : size(POINTS, 1)                             %遍历小尺寸滤波器放置的每一点，用max处理相互覆盖问题
    HNPuv(POINTS(i, 1) : POINTS(i, 1) + 2 * halfLengthOfSideFloor, POINTS(i, 2) : POINTS(i, 2) + 2 * halfLengthOfSideFloor) =  ...
        max(Huv, HNPuv(POINTS(i, 1) : POINTS(i, 1) + 2 * halfLengthOfSideFloor, POINTS(i, 2) : POINTS(i, 2) + 2 * halfLengthOfSideFloor));
end

%放置好小尺寸滤波器后裁剪
HNPuv = HNPuv(1 + halfLengthOfSideFloor : end - halfLengthOfSideFloor, 1 + halfLengthOfSideFloor : end - halfLengthOfSideFloor);
HNPuv = max(HNPuv, rot90(HNPuv, 2));                    %由于对称性，将图像旋转180°后与原图用max处理覆盖问题，得到最终陷波带通模版

% figure('Name', '陷波带通模版');                          %显示陷波带通模版
% imshow(HNPuv, []);
imwrite(HNPuv,'data\mask.png');                         %输出陷波带通模版


%% 实现最佳陷波滤波器
Nuv = HNPuv .* Guv;                                     %陷波带通模版与原图在频域相乘，期望得到周期噪声成分
NuvShift = ifftshift(Nuv);                              %对居中的傅里叶变换结果进行还原
ETAxy = abs(ifft2(NuvShift));                           %进行傅里叶逆变换，得到空间域图像

% figure('Name', '噪声的傅里叶谱')
% imshow(log(abs(Nuv) + 1), []);
% figure('Name', '噪声的模式');                            %显示噪声的模式
% imshow(log(ETAxy), []);


a = 5;                                                  %邻域大小，横向
b = 5;                                                  %邻域大小，纵向
gxy = img;                                              %原图像
fxyHat = zeros(size(gxy));                              %最佳陷波滤波结果图像矩阵
wxy = zeros(size(gxy));                                 %存储每一像素坐标的权值
%边界采用padding补0处理
gxyPadded = zeros([(size(img, 1) + 2 * b), (size(img, 2) + 2 * a)]);            %原图像padding
gxyPadded(b + 1 : b + size(img, 1), a + 1 : a + size(img, 2)) = img;
ETAxyPadded = zeros([(size(img, 1) + 2 * b), (size(img, 2) + 2 * a)]);          %噪声padding
ETAxyPadded(b + 1 : b + size(img, 1), a + 1 : a + size(img, 2)) = ETAxy;
for r = 1 : size(fxyHat, 1)                             %对最佳陷波滤波结果矩阵每一点应用式(5.4-13)，得到最终图像
    for c = 1 : size(fxyHat, 2)
        wxy(r, c) = (mean(mean(gxyPadded(r : r + 2 * b, c : c + 2 * a) .* ETAxyPadded(r : r + 2 * b, c : c + 2 * a))) - ...
            mean(mean(gxyPadded(r : r + 2 * b, c : c + 2 * a))) * mean(mean(ETAxyPadded(r : r + 2 * b, c : c + 2 * a)))) / ...
            (mean(mean((ETAxyPadded(r : r + 2 * b, c : c + 2 * a) .* ETAxyPadded(r : r + 2 * b, c : c + 2 * a)))) - ...
            mean(mean(ETAxyPadded(r : r + 2 * b, c : c + 2 * a))) * mean(mean(ETAxyPadded(r : r + 2 * b, c : c + 2 * a))));
        fxyHat(r, c) = gxy(r, c) - wxy(r, c) * ETAxy(r, c);
    end
end



% figure('Name', '最佳陷波滤波结果');                      %显示最佳陷波滤波结果
% imshow(uint8(fxyHat));                                  %直接转为uint8类型显示
GuvHAT = fft2(fxyHat);
GuvHAT = fftshift(GuvHAT);
% figure('Name', '最佳陷波滤波结果傅里叶谱');               %最佳陷波滤波结果傅里叶谱
% imshow(log(abs(GuvHAT) + 1), []);


%% 直接陷波滤波
DNuv = (1 - HNPuv) .* Guv;                              %用1减去陷波带通模版转换成陷波带阻模版，与原图在频域相乘，期望过滤掉周期噪声成分

% figure('Name', '陷波带阻处理后图像的傅里叶谱');           %显示陷波带阻处理后图像傅里叶谱
% imshow(log(abs(DNuv) + 1), []);

DNuvShift = ifftshift(DNuv);                            %对居中的傅里叶变换结果进行还原
dfxy = abs(ifft2(DNuvShift));                           %进行傅里叶逆变换，得到空间域图像

% figure('Name', '陷波带阻处理后的图像');                  %显示陷波带阻处理后的图像
% imshow(uint8(dfxy));


%% 显示结果
figure('Name', '空间域对比图');
set(gcf,'outerposition',get(0,'screensize'));
subplot(1, 3, 1);
imshow(img);
title('原图');
subplot(1, 3, 2);
imshow(uint8(fxyHat));
title('最佳滤波器处理后图像');
subplot(1, 3, 3);
imshow(uint8(dfxy));
title('陷波滤波器处理后图像');

figure('Name', '频域对比图');
set(gcf,'outerposition',get(0,'screensize'));
subplot(1, 3, 1);
imshow(log(abs(Guv) + 1), []);
title('原图傅里叶谱');
subplot(1, 3, 2);
imshow(log(abs(GuvHAT) + 1), []);
title('最佳滤波器处理后图像傅里叶谱');
subplot(1, 3, 3);
imshow(log(abs(DNuv) + 1), []);
title('陷波滤波器处理后图像傅里叶谱');

figure('Name', '其他');
set(gcf,'outerposition',get(0,'screensize'));
subplot(1, 3, 1);
imshow(Huv, []);
title('小尺寸 Butterworth 低通滤波器');
subplot(1, 3, 2);
imshow(HNPuv, []);
title('陷波带通模版');
subplot(1, 3, 3);
imshow(log(ETAxy), []);
title('噪声的模式');


toc;                                        %计时结束
