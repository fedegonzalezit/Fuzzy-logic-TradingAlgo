%%
%Generación de vectores:
rsi = importdata('technical_indicator_BTCUSD_RSI.csv');
macd = importdata('technical_indicator_BTCUSD_MACD.csv');
so = importdata('technical_indicator_BTCUSD_STOCH.csv');
adx = importdata('technical_indicator_BTCUSD_ADX.csv');
price = importdata('daily_BTCUSD.csv');

jornadas= 2000;

%%
%transformacion a vectores

adx_data = fliplr(transpose(adx.data(1:jornadas)));
adx_data = adx_data./100;  %Normalizo entre 0 y 1

%%
so_data = so.data(:,1);
so_data = transpose(so_data(1:jornadas));
so_data = fliplr(so_data);
so_data = so_data./100;
%%

rsi_data = transpose(rsi.data(1:jornadas));
rsi_data = fliplr(rsi_data);
rsi_data = rsi_data./100;

%%
macd_data = macd.data(:,2);
macd_data = transpose(macd_data(1:jornadas));
macd_data = fliplr(macd_data);



%%

prices2 = price.data(:,4);
prices2 = transpose(prices2(1:jornadas));
prices2 = fliplr(prices2);

%%
%macd como porcentaje del precio
macd_data = (macd_data./prices2).*100;
macd_data(macd_data>10) = 10;

macd_data(macd_data<-10) = -10;

%%

inputs = [macd_data; rsi_data; so_data; adx_data];
%%
%abro el fis
fis = readfis('Fuzzy-control2.fis');


%%
%Resultados

outputs = evalfis(inputs, fis);


%%
%Visualizacion de resultados
%% A PARTIR DE ACA ES TODO LO QUE HAY QUE MODIFICAR Y VER COMO LO HACEMOS PROLIJO



comprado = zeros(1, jornadas);
manteniendo = zeros(1, jornadas);
vendido = zeros(1, jornadas);

dias_comprado = 0;
dias_manteniendo = 0;
dias_vendido = 0;

last = 1;

acumulado = 1;
last_price=prices2(1);
last_price_sold = prices2(1);

operaciones_exitosas = 0;
operaciones_negativas = 0;



for i = 1:length(outputs)
       if(outputs(i) < 10)
           vendido(i) = prices2(i);
           dias_vendido = dias_vendido + 1;
           if(last == 2)
               last_price_sold = prices2(i);
               rendimiento = ((prices2(i)/last_price)-1)*100;
               if(prices2(i) > last_price)
                   operaciones_exitosas = operaciones_exitosas+1;
               else
                   operaciones_negativas = operaciones_negativas+1;
               end
               acumulado = (prices2(i)/last_price)*acumulado;
           end
           last = 0;
       elseif(outputs(i)> 10 && outputs(i)<20)
           manteniendo(i) = prices2(i);
           dias_manteniendo = dias_manteniendo+1;
           if (last == 0)
               vendido(i) = prices2(i);
           elseif(last == 2)
               comprado(i) = prices2(i);
           end
       elseif(outputs(i)>20)
           comprado(i) = prices2(i);
           dias_comprado = dias_comprado+1;
           if (last == 0)
               last_price = prices2(i);
               if(prices2(i) < last_price_sold)
                   operaciones_exitosas = operaciones_exitosas+1;
               else
                   operaciones_negativas = operaciones_negativas+1;
               end
           end
           
     
           last = 2;
       end
end

%%

rendimiento_fuzzy = (acumulado-1)*100
rendimiento_buy_and_hold = (prices2(jornadas)/prices2(1)-1)*100


%%####################################################################
%%  Agregado para graficar 
%%####################################################################


Precio = price.data(:,4);   %tomo la cotizacion al cierre
Precio = transpose(Precio(1:jornadas)); %corto la serie en 2000 desde el 2020 hacia atras
Precio = fliplr(Precio); % Ordeno desde el mas viejo al mas nuevo.
Precio = transpose(Precio);



%%
% Simulacion de rendimiento:
% Entrada = Output, Interpretacion  
%  0 a 10 => Vender 1
% 10 a 20 => Mantener 2
% mayor a 20 => Comprar 3

Procesado(length(outputs),1)=0; %reservo los valores para que se ejecute mas rapido el script
Procesado(length(outputs),2)=0;
Tabla(length(outputs),2)=0;


for i = 1:length(outputs)
if (outputs(i) < 10)
    Procesado(i,1) = outputs(i);    % data( numero fila , numero de columna) = dato
    Procesado(i,2) = 1;             % data = ( numero fila , numero de columna) Vender
    Tabla(i,1)=prices2(i);
    Tabla(i,2)=1;
elseif (outputs(i) < 20)
    Procesado(i,1) = outputs(i);    % data( numero fila , numero de columna) = dato
    Procesado(i,2) = 2;             % data = ( numero fila , numero de columna) Mantener
    Tabla(i,1)=prices2(i);
    Tabla(i,2)=2;
else
    Procesado(i,1) = outputs(i);    % data( numero fila , numero de columna) = dato
    Procesado(i,2) = 3;             % data = ( numero fila , numero de columna) Comprar
    Tabla(i,1)=prices2(i);
    Tabla(i,2)=3;
end
end


AccionesAcumulado(length(Procesado))= 0;
Capital=Precio(1);  % Empiezo con una accion.
CantidadDeAcciones =Capital/Precio(1);  %Compro todas las acciones que puedo
AccionesAcumulado(1)=CantidadDeAcciones; %Solo tengo acciones
CapitalAcumulado(length(Procesado)) = 0; %quiero mantener siempre el precio.
CapitalAcumulado(1)=Capital;
PrecioDeCompra=Precio(1);
Capital=1;
CapitalAcumuladoV2 (length(Procesado)) = 0;
CapitalAcumuladoV2(1) = 1;


Precio_normalizado = Precio./Precio(1);
PrecioCompra = 1;
CantidadDeAcciones= 0;
CapitalCompra=1;

dias_comprado=0;

% compra y vende todo
for i = 2:length(Procesado)
    if(CantidadDeAcciones == 1)
        dias_comprado = dias_comprado + 1;
    end
switch Procesado(i,2)
   case 1 %Vender
        if (CantidadDeAcciones>0)
            Capital = (Precio(i)/PrecioCompra)*CapitalCompra;
            CantidadDeAcciones = 0;
        end
        CapitalAcumuladoV2(i)= Capital; 
   case 2 %Mantener
       if(CantidadDeAcciones>0)
           Capital = (Precio(i)/PrecioCompra)*CapitalCompra; 
       end
       CapitalAcumuladoV2(i) = Capital;
   case 3 %Comprar
       if(CantidadDeAcciones == 0)
           PrecioCompra = Precio(i);
           CapitalCompra = Capital;
       end
       CantidadDeAcciones = 1;
       Capital = (Precio(i)/PrecioCompra)*CapitalCompra; 
       CapitalAcumuladoV2(i) = Capital; 
   
end
end



CantidadDeAcciones=Capital/Precio(i);


%%
%ploteo de resultados

hold on

yplot= comprado;             
yplot(yplot==0)=nan;

plot([0:1:jornadas-1], yplot, 'g');


yplot= vendido;             
yplot(yplot==0)=nan;

plot([0:1:jornadas-1], yplot, 'r');

%yplot= manteniendo;             

%yplot(yplot==0)=nan;

%plot([0:1:jornadas-1], yplot, 'b');

%plot(0:1:jornadas-1, macd_data.*100);


%hold off

%%Agrego aca calculo

%%#################################################
%% Grafico 
%%#################################################
figure

hold on

ytickformat('usd')

yplot= comprado;             
yplot(yplot==0)=nan;

%plot([0:1:jornadas-1], yplot, 'g');


yplot= vendido;             
yplot(yplot==0)=nan;

%plot([0:1:jornadas-1], yplot, 'r');

plot([0:1:jornadas-1], Precio_normalizado);

hold on


%plot(Precio);
hold on
plot(CapitalAcumuladoV2);


rendimiento_anual_buy_and_hold = rendimiento_buy_and_hold*260/jornadas
rendimiento_anual_fuzzy = rendimiento_fuzzy*260/dias_comprado

%legend({'comprando','vendiendo','Capital'},'Location','northwest') % genera leyendas en norte este 
%legend({'Comprar','Vender','Capital'},'Location','northwest')


