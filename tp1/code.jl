using JuMP, Gurobi

# Inicialização do modelo
model = Model(Gurobi.Optimizer)

# Parâmetros

T = 72  # Horizonte de 72h

buildings = [
    "Main Building",      # Edifício principal
    "Warehouse",          # Armazém
    "Granary",            # Celeiro
    "Barracks",           # Quartel
    "Academy",            # Academia
    "Smithy",             # Ferreiro
    "Woodcutter",         # Campo de madeira
    "Clay Pit",           # Campo de barro
    "Iron Mine",          # Campo de ferro
    "Cropland"            # Campo de cereal
]

resources = ["Wood", "Clay", "Iron", "Crop"] # Tipos de Recursos

# Inicialização do dicionário de requisitos de construção
building_requirements = Dict{String, Dict{String, Int}}()

# Variáveis de decisão

# x[s, l, t] binária: se o nível l da construção s foi iniciado no tempo t
@variable(model, x[eachindex(buildings), 1:20, 1:T], Bin)

# n[s, l, t] inteira: quantidade de níveis l da construção s completos até o tempo t
@variable(model, n[eachindex(buildings), 1:20, 1:T] >= 0, Int)

# r[r, t] quantidade de recursos r disponíveis no tempo t
@variable(model, r[eachindex(resources), 1:T] >= 0, Int)

# q_t número de soldados treinados até o tempo t
@variable(model, q_t[1:T] >= 0, Int)

# q número total de soldados treinados
@variable(model, q >= 0, Int)

# Recursos iniciais
for r_i in eachindex(resources)
    @constraint(model, r[r_i, 1] == 750)
end

# Main Building e campos de recurso já construídos no nível 1
for (s, name) in enumerate(buildings)
    if name == "Main Building" || name in ["Woodcutter", "Clay Pit", "Iron Mine", "Cropland"]
        @constraint(model, n[s, 1, 1] == 1)
    end
end

# Produção de cada campo de recurso por nível (unidades por hora)
resource_production = Dict(
    "Woodcutter" => Dict(l => 5 * l for l in 1:20),
    "Clay Pit"   => Dict(l => 5 * l for l in 1:20),
    "Iron Mine"  => Dict(l => 5 * l for l in 1:20),
    "Cropland"   => Dict(l => 5 * l for l in 1:20)
)

function building_for_resource(res)
    if res == "Wood"
        return "Woodcutter"
    elseif res == "Clay"
        return "Clay Pit"
    elseif res == "Iron"
        return "Iron Mine"
    elseif res == "Crop"
        return "Cropland"
    end
end

for t in 2:T, r_i in eachindex(resources)
    resource = resources[r_i]
    @constraint(model,
        r[r_i, t] ==
        r[r_i, t-1] +
        sum(sum(n[s, l, t-1] * resource_production[buildings[s]][l]
            for l in 1:20)
            for s in eachindex(buildings)
            if haskey(resource_production, buildings[s]) && buildings[s] == building_for_resource(resource)
        )
        # - consumo aqui se quiser considerar treinamento e construção
    )
end

# Custos para cada tipo de construção
resource_required = Dict()

# Valores de Main Building
for lvl in 1:19
    main_building_costs = [
        70   40   60   20;
        90   50   75   25;
        115  65  100   35;
        145  85  125   40;
        190 105  160   55;
        240 135  205   70;
        310 175  265   90;
        395 225  340  115;
        505 290  430  145;
        645 370  555  185;
        825 470  710  235;
        1060 605 905 300;
        1355 775 1160 385;
        1735 990 1485 495;
        2220 1270 1900 635;
        2840 1625 2435 810;
        3635 2075 3115 1040;
        4650 2660 3990 1330;
        5955 3405 5105 1700;
        7620 4355 6535 2180
    ]
    resource_required["Main Building", lvl] = Dict(
        "Wood" => main_building_costs[lvl, 1],
        "Clay" => main_building_costs[lvl, 2],
        "Iron" => main_building_costs[lvl, 3],
        "Crop" => main_building_costs[lvl, 4]
    )
end

# Valores de Barracks
for lvl in 1:20
    barracks_costs = [
        210   140   260   120;
        270   180   335   155;
        345   230   425   195;
        440   295   545   250;
        565   375   700   320;
        720   480   895   410;
        925   615  1145   530;
        1180  790  1463   675;
        1515 1010  1875   865;
        1935 1290  2400  1105;
        2480 1655  3070  1415;
        3175 2115  3930  1815;
        4060 2710  5030  2320;
        5200 3465  6435  2970;
        6655 4435  8240  3805;
        8520 5680 10545  4870;
        10905 7270 13500 6230;
        13955 9305 17280 7975;
        17865 11910 22120 10210;
        22865 15245 28310 13065
    ]
    resource_required["Barracks", lvl] = Dict(
        "Wood" => barracks_costs[lvl, 1],
        "Clay" => barracks_costs[lvl, 2],
        "Iron" => barracks_costs[lvl, 3],
        "Crop" => barracks_costs[lvl, 4]
    )
end

# Valores de Warehouse
for lvl in 1:20
    warehouse_costs = [
        130   160    90   40;
        165   205   115   50;
        215   260   145   65;
        275   335   190   85;
        350   430   240  105;
        445   550   310  135;
        570   705   395  175;
        730   900   505  225;
        935  1155   650  290;
        1200 1475   830  370;
        1535 1890  1065  470;
        1965 2420  1360  705;
        2515 3195  1740  975;
        3220 3960  2230  990;
        4120 5070  2850 1270;
        5275 6490  3650 1625;
        6750 8310  4675 2075;
        8640 10635 5980 2660;
        11060 13610 7655 3405;
        14155 17420 9800 4355
    ]
    resource_required["Warehouse", lvl] = Dict(
        "Wood" => warehouse_costs[lvl, 1],
        "Clay" => warehouse_costs[lvl, 2],
        "Iron" => warehouse_costs[lvl, 3],
        "Crop" => warehouse_costs[lvl, 4]
    )
end

# Valores de Granary
for lvl in 1:20
    granary_costs = [
        80    100   70    20   270;
        100   130   90    25   345;
        130   165   115   35   445;
        170   210   145   40   565;
        215   270   190   55   730;
        275   345   240   70   930;
        350   440   310   90   1190;
        450   565   395   115  1525;
        575   720   505   145  1945;
        740   920   645   185  2490;
        945   1180  825   235  3185;
        1210  1510  1060  300  4080;
        1545  1935  1355  385  5220;
        1980  2475  1735  495  6685;
        2535  3170  2220  635  8560;
        3245  4055  2840  810  10950;
        4155  5190  3635  1040 14020;
        5315  6645  4650  1330 17940;
        6805  8505  5955  1700 22965;
        8710  10890 7620  2180 29400
    ]
    resource_required["Granary", lvl] = Dict(
        "Wood" => granary_costs[lvl, 1],
        "Clay" => granary_costs[lvl, 2],
        "Iron" => granary_costs[lvl, 3],
        "Crop" => granary_costs[lvl, 4],
        "Upkeep" => granary_costs[lvl, 5]
    )
end

# Valores de Blacksmith
for lvl in 1:20
    blacksmith_costs = [
        180   250   500   160;
        220   255   485   165;
        280   330   625   215;
        355   420   795   275;
        455   535  1020   350;
        585   685  1305   445;
        750   880  1670   570;
        955  1125  2140   730;
        1225 1440  2740   935;
        1570 1845  3505  1200;
        2005 2360  4485  1535;
        2570 3020  4740  1965;
        3290 3870  7350  2515;
        4210 4950  9410  3220;
        5390 6340 12045  4120;
        6895 8115 15415  5275;
        8825 10385 19730 6750;
        11300 13290 25255 8640;
        14460 17015 32325 11060;
        18510 21780 41380 14155
    ]

    resource_required["Blacksmith", lvl] = Dict(
        "Wood" => blacksmith_costs[lvl, 1],
        "Clay" => blacksmith_costs[lvl, 2],
        "Iron" => blacksmith_costs[lvl, 3],
        "Crop" => blacksmith_costs[lvl, 4]
    )
end
building_requirements["Blacksmith"] = Dict("Academy" => 3, "Main Building" => 3, "Barracks" => 3)

# Valores de Woodcutter
for lvl in 1:20
    woodcutter_costs = [
        40     100    50     60;
        65     165    85    100;
        110    280   140    165;
        185    465   235    280;
        310    780   390    465;
        520   1300   650    780;
        870   2170  1085   1300;
        1450  3625  1810   2175;
        2420  6050  3025   3630;
        4040 10105  5050   6060;
        6750 16870  8435  10125;
        11270 28175 14090 16905;
        18820 47055 23525 28230;
        31430 78580 39290 47150;
        52490 131230 65615 78740;
        87660 219155 109755 131490;
        146395 365985 182995 219590;
        244480 611195 305600 366715;
        408280 1020695 510350 612420;
        681825 1704565 852280 1022740
    ]

    resource_required["Woodcutter", lvl] = Dict(
        "Wood" => woodcutter_costs[lvl, 1],
        "Clay" => woodcutter_costs[lvl, 2],
        "Iron" => woodcutter_costs[lvl, 3],
        "Crop" => woodcutter_costs[lvl, 4]
    )
end
building_requirements["Woodcutter"] = Dict()

# Valores para Clay Pit
for lvl in 1:20
    clay_pit_costs = [
        40     100    50     60;
        65     165    85    100;
        110    280   140    165;
        185    465   235    280;
        310    780   390    465;
        520   1300   650    780;
        870   2170  1085   1300;
        1450  3625  1810   2175;
        2420  6050  3025   3630;
        4040 10105  5050   6060;
        6750 16870  8435  10125;
        11270 28175 14090 16905;
        18820 47055 23525 28230;
        31430 78580 39290 47150;
        52490 131230 65615 78740;
        87660 219155 109755 131490;
        146395 365985 182995 219590;
        244480 611195 305600 366715;
        408280 1020695 510350 612420;
        681825 1704565 852280 1022740
    ]

    resource_required["Clay Pit", lvl] = Dict(
        "Wood" => clay_pit_costs[lvl, 1],
        "Clay" => clay_pit_costs[lvl, 2],
        "Iron" => clay_pit_costs[lvl, 3],
        "Crop" => clay_pit_costs[lvl, 4]
    )
end
building_requirements["Clay Pit"] = Dict()

# Valores para Iron Mine
for lvl in 1:20
    iron_mine_costs = [
        100     80     30     60;
        165    135     50    100;
        280    225     85    165;
        465    375    140    280;
        780    620    235    465;
        1300  1040    390    780;
        2170  1735    650   1300;
        3625  2900   1085   2175;
        6050  4840   1815   3630;
        10105 8080   3030   6060;
        16870 13500  5060  10125;
        28175 22540  8455  16905;
        47055 37645 14115  28230;
        78580 62865 23575  47150;
        131230 104985 39370 78740;
        219155 175320 65745 131490;
        365985 292790 109795 219590;
        611195 488955 183360 366715;
        1020695 816555 306210 612420;
        1704565 1363650 511370 1022740
    ]

    resource_required["Iron Mine", lvl] = Dict(
        "Wood" => iron_mine_costs[lvl, 1],
        "Clay" => iron_mine_costs[lvl, 2],
        "Iron" => iron_mine_costs[lvl, 3],
        "Crop" => iron_mine_costs[lvl, 4]
    )
end
building_requirements["Iron Mine"] = Dict()

#Valores para Cropland
for lvl in 1:20
    cropland_costs = [
        70     90     70     20;
        115   150    115     35;
        195   250    195     55;
        325   420    325     95;
        545   700    545    155;
        910  1170    910    260;
        1520 1950   1520    435;
        2535 3260   2535    725;
        4235 5445   4235   1210;
        7070 9095   7070   2020;
        11810 15185 11810  3375;
        19725 25360 19725  5635;
        32940 42350 32940  9410;
        55005 70720 55005 15715;
        91860 118105 91860 26245;
        153405 197240 153405 43830;
        256190 329385 256190 73195;
        427835 550075 427835 122240;
        714485 918625 714485 204140;
        1193195 1534105 1193195 340915
    ]

    resource_required["Cropland", lvl] = Dict(
        "Wood" => cropland_costs[lvl, 1],
        "Clay" => cropland_costs[lvl, 2],
        "Iron" => cropland_costs[lvl, 3],
        "Crop" => cropland_costs[lvl, 4]
    )
end
building_requirements["Cropland"] = Dict()

# Capacidade de armazenamento padrão
storage_capacity = Dict("Wood"=>800, "Clay"=>800, "Iron"=>800, "Crop"=>800)

# Custos, tempo de treinamento e requisitos das tropas romanas
soldier_data = Dict(
    "Legionnaire" => Dict(
        "Cost" => Dict("Wood"=>120, "Clay"=>100, "Iron"=>150, "Crop"=>30),
        "TrainingTime" => "n/a",
        "Requirements" => ["Barracks level 1"]
    ),
    "Praetorian" => Dict(
        "Cost" => Dict("Wood"=>700, "Clay"=>620, "Iron"=>1480, "Crop"=>580),
        "TrainingTime" => "2:20:00",
        "Requirements" => ["Armory level 1"]
    ),
    "Imperian" => Dict(
        "Cost" => Dict("Wood"=>1000, "Clay"=>740, "Iron"=>1880, "Crop"=>640),
        "TrainingTime" => "2:30:00",
        "Requirements" => ["Armory level 1"]
    ),
    "Equites Legati" => Dict(
        "Cost" => Dict("Wood"=>940, "Clay"=>740, "Iron"=>360, "Crop"=>400),
        "TrainingTime" => "1:55:00",
        "Requirements" => ["Stable level 1"]
    ),
    "Equites Imperatoris" => Dict(
        "Cost" => Dict("Wood"=>3400, "Clay"=>1860, "Iron"=>2760, "Crop"=>760),
        "TrainingTime" => "3:15:00",
        "Requirements" => ["Stable level 5"]
    ),
    "Equites Caesaris" => Dict(
        "Cost" => Dict("Wood"=>3400, "Clay"=>2660, "Iron"=>6600, "Crop"=>1240),
        "TrainingTime" => "4:10:00",
        "Requirements" => ["Stable level 10"]
    ),
    "Battering Ram" => Dict(
        "Cost" => Dict("Wood"=>5500, "Clay"=>1540, "Iron"=>4200, "Crop"=>580),
        "TrainingTime" => "4:20:00",
        "Requirements" => ["Workshop level 1"]
    ),
    "Fire Catapult" => Dict(
        "Cost" => Dict("Wood"=>5800, "Clay"=>5500, "Iron"=>5000, "Crop"=>700),
        "TrainingTime" => "8:00:00",
        "Requirements" => ["Workshop level 10"]
    ),
    "Senator" => Dict(
        "Cost" => Dict("Wood"=>15880, "Clay"=>13800, "Iron"=>36400, "Crop"=>22660),
        "TrainingTime" => "6:47:55",
        "Requirements" => ["Rally point level 10"]
    )
)

# Restrições

# Construção única por nível
for s in eachindex(buildings), l in 1:20
    @constraint(model, sum(x[s, l, t] for t in 1:T) <= 1)
end

# Apenas um edifício de cada tipo (exceto campos de recurso)
for s in eachindex(buildings)
    @constraint(model, sum(x[s, l, t] for l in 1:20, t in 1:T) == 1)
end

# Disponibilidade de recursos (em cada tempo t)
for r_i in eachindex(resources), t in 1:T
    @constraint(model, r[r_i, t] <= storage_capacity[resources[r_i]])
end

# Requisitos de construção (campos de recurso)
for r in eachindex(resources), t in 1:T
    @constraint(model, sum(x[s, l, t] * resource_required[buildings[s], l][r] for s in eachindex(buildings), l in 1:20) <= r[r, t])
end

# O quartel deve existir antes de treinar soldados
@constraint(model, sum(x[4, l, t] for l in 1:20, t in 1:T) >= 1)

# Recursos suficientes para treinamento de soldados
@constraint(model, sum(q_t[t] * soldier_cost[resources[r]] for t in 1:T for r in eachindex(resources)) <= sum(r[r, t] for r in eachindex(resources), t in 1:T))

# Quantidade mínima de soldados
@constraint(model, q >= 100)

# Função objetivo
@objective(model, Max, q)

# Resolver o modelo
optimize!(model)

# Exibir resultados
if termination_status(model) == MOI.OPTIMAL
    println("Solução ótima encontrada!")
    println("Número total de soldados: ", value(q))
else
    println("Não foi possível encontrar uma solução ótima.")
end