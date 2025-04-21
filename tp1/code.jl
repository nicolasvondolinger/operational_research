using JuMP, Gurobi

model = Model(Gurobi.Optimizer)

T = 259200  # Horizonte de 72h em segundos

levels = 1:20 

buildings = [
    "Main Building",      # Edifício principal
    "Warehouse",          # Armazém
    "Granary",            # Celeiro
    "Barracks",           # Quartel
    "Academy",            # Academia
    "Woodcutter",         # Campo de madeira
    "Clay Pit",           # Campo de barro
    "Iron Mine",          # Campo de ferro
    "Cropland",           # Campo de cereal
    "Rally Point"         # Ponto de Encontro 
]

resources = ["Wood", "Clay", "Iron", "Crop"]

resource_buildings = ["Woodcutter", "Clay Pit", "Iron Mine", "Cropland"]

# População gerada por cada nível de cada construção

population = Dict{String, Vector{Int}}()

population["Main Building"] = [2, 1, 1, 1, 1, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 3, 3, 3, 3, 3]

population["Warehouse"] = [1, 1, 2, 2, 1, 1, 1, 1, 1, 1, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2]

population["Granary"] = [1, 1, 2, 2, 2, 1, 1, 1, 1, 1, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2]

population["Barracks"] = [1, 1, 2, 2, 2, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 4, 4, 4, 4, 4]

population["Academy"] = [4, 2, 2, 2, 2, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 4, 4, 4, 4, 4]

population["Woodcutter"] = [1, 1, 1, 2, 2, 2, 4, 4, 5, 6, 7, 9, 11, 13, 15, 18, 22, 27, 32, 38]

population["Clay Pit"] = [1, 1, 1, 2, 2, 2, 4, 4, 5, 6, 7, 9, 11, 13, 15, 18, 22, 27, 32, 38]

population["Iron Mine"] = [1, 1, 2, 2, 2, 3, 4, 4, 5, 6, 7, 9, 11, 13, 15, 18, 22, 27, 32, 38]

population["Cropland"] = [0, 0, 0, 0, 0, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 2, 2, 2, 2, 2]

population["Rally Point"] = [1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2]

# Variáveis de decisão

@variable(model, total_population[1:T] >= 0, Int)

# x[s, l, t] binária: se o nível l da construção s foi iniciado no tempo t
@variable(model, x[eachindex(buildings), 1:20, 1:T], Bin)

# n[s, l, t] binária: se a construção s tem o nível l completo no tempo t
@variable(model, n[eachindex(buildings), 1:20, 1:T] >= 0, Bin)

# r[r, t] quantidade de recursos r disponíveis no tempo t
@variable(model, r[resources, 1:T] >= 0, Int)

# q número total de soldados treinados
@variable(model, q >= 0, Int)

# q_t número de soldados treinados até o tempo t
@variable(model, q_t[1:T] >= 0, Int)

# Relação entre q e q_t
@constraint(model, q == sum(q_t[t] for t in 1:T))

# Variável de capacidade
@variable(model, w[resources, 1:T] >= 0)

# Recursos iniciais
for res in resources
    @constraint(model, r[res, 1] == 750)
end

for t in 1:T
    @constraint(model, total_population[t] == sum(
        n[s, l, t] * population[buildings[s]][l]
        for s in eachindex(buildings) 
        for l in 1:20
        if haskey(population, buildings[s])
    ))
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

# Custos para cada tipo de construção
resource_required = Dict()

# Inicialização do dicionário de requisitos de cada construção
building_requirements = Dict{String, Dict{String, Int}}()

# Custos de Main Building
for lvl in 1:20
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
building_requirements["Main Building"] = Dict()

# Custos de Barracks
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
building_requirements["Barracks"] = Dict("Main Building" => 3, "Rally Point" => 1)

# Custos de Academy
for lvl in 1:20
    academy_costs = [
        220   160    90    40;
        280   205   115    50;
        360   260   145    65;
        460   335   190    85;
        590   430   240   105;
        755   550   310   135;
        970   705   395   175;
        1240  900   505   225;
        1585 1155   650   290;
        2030 1475   830   370;
        2595 1890  1065   470;
        3325 2420  1360   605;
        4255 3095  1740   775;
        5445 3960  2230   990;
        6970 5070  2850  1270;
        8925 6490  3650  1625;
        11425 8310 4675  2075;
        14620 10635 5980 2660;
        18715 13610 7655 3405;
        23955 17420 9800 4355
    ]

    resource_required["Academy", lvl] = Dict(
        "Wood" => academy_costs[lvl, 1],
        "Clay" => academy_costs[lvl, 2],
        "Iron" => academy_costs[lvl, 3],
        "Crop" => academy_costs[lvl, 4]
    )
end
building_requirements["Academy"] = Dict()

# Custos de Warehouse
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
building_requirements["Warehouse"] = Dict()

# Custos de Granary
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
building_requirements["Granary"] = Dict()

# Custos de Woodcutter
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

# Custos de Clay Pit
for lvl in 1:20
    clay_pit_costs = [
        80    40    80    50;
        135   65   135    85;
        225  110   225   140;
        375  185   375   235;
        620  310   620   390;
        1040 520  1040   650;
        1735 870  1735  1085;
        2900 1450 2900  1810;
        4840 2420 4840  3025;
        8080 4040 8080  5050;
        13500 6750 13500 8435;
        22540 11270 22540 14090;
        37645 18820 37645 23525;
        62865 31430 62865 39290;
        104985 52490 104985 65615;
        175320 87660 175320 109575;
        292790 146395 292790 182995;
        488955 244480 488955 305600;
        816555 408280 816555 510350;
        1363650 681825 1363650 852280
    ]

    resource_required["Clay Pit", lvl] = Dict(
        "Wood" => clay_pit_costs[lvl, 1],
        "Clay" => clay_pit_costs[lvl, 2],
        "Iron" => clay_pit_costs[lvl, 3],
        "Crop" => clay_pit_costs[lvl, 4]
    )
end
building_requirements["Clay Pit"] = Dict()

# Custos de Iron Mine
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

# Custos de Cropland
for lvl in 1:20
    cropland_costs = [
         70    90     70     20;
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

# Custos de Rally Point
for lvl in 1:20
    rally_point_costs = [
        110   160   90   70;
        140   205  115   90;
        180   260  145  115;
        230   335  190  145;
        295   430  240  190;
        380   550  310  240;
        485   705  395  310;
        615   900  505  395;
        790  1155  645  505;
        1010 1475  830  650;
        1290 1890 1060  830;
        1655 2420 1360 1065;
        2115 3100 1740 1360;
        2710 3965 2225 1740;
        3485 5070 2850 2220;
        4460 6490 3650 2840;
        5710 8310 4675 3635;
        7270 10645 5970 4675;
        9305 13625 7645 5980;
        11910 17440 9785 7655
    ]

    resource_required["Rally Point", lvl] = Dict(
        "Wood" => rally_point_costs[lvl, 1],
        "Clay" => rally_point_costs[lvl, 2],
        "Iron" => rally_point_costs[lvl, 3],
        "Crop" => rally_point_costs[lvl, 4]
    )
end
building_requirements["Rally Point"] = Dict()

# Produção de recursos e consumo
for t in 2:T, res_name in resources
    building_name = building_for_resource(res_name)
    s = findfirst(==(building_name), buildings)
    
    production = if building_name ∈ resource_buildings
        sum(
            n[s, l, t-1] * resource_production[building_name][l] / 3600
            for l in 1:20
        )
    else
        0
    end
    
    consumption = sum(
        x[s_b, l, t] * resource_required[buildings[s_b], l][res_name]
        for s_b in eachindex(buildings), l in 1:20
    ) + (res_name == "Crop" ? (total_population[t] + q_t[t]) / 3600 : 0)
    
    @constraint(model, r[res_name, t] == r[res_name, t-1] + production - consumption)
end

# Consumo de Crop
@constraint(model, [t in 1:T],
    r["Crop", t] >= (total_population[t] + q_t[t]) / 3600
)

# Tempo necessário para cada construção em cada nível

building_base_times = Dict(
    "Main Building" => [2000, 2620, 3340, 4170, 5140, 6260, 7570, 9080, 10830, 12860, 15220, 17950, 21130, 24810, 29080, 34030, 39770, 46440, 54170, 63130],
    "Barracks" => [1860, 2430, 3100, 3880, 4780, 5820, 7030, 8430, 10060, 11950, 14140, 16680, 19630, 23050, 27020, 31620, 36960, 43150, 50340, 58670],
    "Academy" => [1860, 2430, 3100, 3880, 4780, 5820, 7030, 8430, 10060, 11950, 14140, 16680, 19630, 23050, 27020, 31620, 36960, 43150, 50340, 58670],
    "Warehouse" => [2000, 2430, 3340, 4170, 5140, 6260, 7570, 9080, 10830, 12860, 15220, 17950, 21130, 24810, 29080, 34030, 39770, 46440, 54170, 63130],
    "Granary" => [1600, 2160, 2800, 3550, 4420, 5420, 6590, 7950, 9520, 11340, 13420, 15850, 18670, 21930, 25720, 30120, 35210, 41110, 47920, 55820],  
    "Woodcutter" => [1200, 1800, 2700, 4050, 6075, 9113, 13669, 20504, 30756, 46134, 69201, 103802, 155703, 233555, 350333, 525500, 788250, 1182375, 1773563, 2660345],
    "Clay Pit" => [260, 620, 1190, 2100, 3560, 5890, 9620, 15590, 25150, 40440, 64900, 104050, 166680, 266880, 427210, 683730, 1091770, 1758880, 2804000, 4497170],
    "Iron Mine" => [450, 920, 1670, 2880, 4800, 7880, 12810, 20690, 33310, 53510, 85800, 137480, 220170, 352410, 564060, 902550, 1444120, 2310620, 3697000, 5915200],
    "Cropland" => [150, 440, 900, 1650, 2830, 4730, 7780, 12620, 20430, 33080, 53410, 86090, 138650, 223220, 359290, 578210, 930510, 1496930, 2407940, 3872980],
    "Rally Point" => [2000, 2620, 3340, 4170, 5140, 6260, 7570, 9080, 10830, 12860, 15230, 17970, 21130, 24750, 28900, 33660, 39110, 45340, 52450, 60530], 
)

building_times = Dict(
    s => [ceil(1.3 * t / 3) for t in times] 
    for (s, times) in building_base_times
)

# Custo para treinar um Legionário
soldier_cost = Dict(
    "Wood" => 120,
    "Clay" => 100, 
    "Iron" => 150,
    "Crop" => 30
)

# Custos, tempo de treinamento e requisitos das tropas romanas
soldier_data = Dict(
    "Legionnaire" => Dict(
        "Cost" => soldier_cost, 
        "TrainingTime" => 0,
        "Requirements" => ["Barracks level 1"]
    )
)

# Restrições

# Construção única por nível
for s in eachindex(buildings), l in 1:20
    @constraint(model, sum(x[s, l, t] for t in 1:T) <= 1)
end

# Limite de 15 construções adicionais (excluindo as 5 iniciais)
initial_buildings = ["Main Building", "Woodcutter", "Clay Pit", "Iron Mine", "Cropland"]
@constraint(model, 
    sum(x[s, l, t] 
        for s in eachindex(buildings) 
        if !(buildings[s] in initial_buildings)
        for l in 1:20 
        for t in 1:T) <= 15
)

# Apenas um edifício de cada tipo (exceto campos de recurso)
for s in eachindex(buildings)
    if buildings[s] ∉ resource_buildings  # Apenas para edifícios únicos
        @constraint(model, sum(x[s, l, t] for l in 1:20, t in 1:T) <= 1)
    end
end

# Disponibilidade de recursos (em cada tempo t)
@constraint(model, [res in resources, t in 1:T], r[res, t] <= w[res, t])

# Construções só podem ser feitas atendendo os requisitos
for s in eachindex(buildings), l in 1:20, t in 1:T
    for (req_building, req_level) in building_requirements[buildings[s]]
        req_s = findfirst(==(req_building), buildings)
        @constraint(model, x[s, l, t] <= sum(n[req_s, req_level, τ] for τ in 1:t-1))
    end
end

# Requisitos de construção (campos de recurso) 
for t in 1:T, resource_name in resources 
    @constraint(model, 
        sum(
            x[s, l, t] * resource_required[buildings[s], l][resource_name] 
            for s in eachindex(buildings), l in 1:20
        ) <= r[resource_name, t] 
    )
end

# Tempo de construção
for s in eachindex(buildings), l in 1:20, t in 1:T
    build_time = Int(ceil(building_times[buildings[s]][l]))
    @constraint(model, 
        n[s,l,t] >= sum(x[s,l,τ] for τ in 1:t-build_time if τ > 0)
    )
end

# O quartel deve existir antes de treinar soldados
@constraint(model, sum(x[4, l, t] for l in 1:20, t in 1:T) >= 1)

# Recursos suficientes para treinamento de soldados
@constraint(model, 
    sum(
        q_t[t] * soldier_cost[r_name] 
        for t in 1:T, 
        r_name in resources
    ) <= 
    sum(
        r[r_name, t]
        for r_name in resources, 
        t in 1:T
    )
)

# Restrição de completude de construção
@constraint(model, [s_idx in eachindex(buildings), l in levels, t in 1:T],
    n[s_idx,l,t] == sum(x[s_idx,l,τ] for τ in 1:t-Int(floor(building_times[buildings[s_idx]][l])) if τ > 0)
)

# Hierarquia de níveis
@constraint(model, [s_idx in eachindex(buildings), l in 2:20, t in 1:T],
    sum(x[s_idx,l,τ] for τ in 1:t) <= sum(x[s_idx,l-1,τ] for τ in 1:t))

# Consumo de cereal por segundo
@constraint(model, [t in 1:T],
    r["Crop", t] >= (total_population[t] + q_t[t]) / 3600
)

# Restrição de treinamento
@constraint(model, [t in 1:T, res_name in resources],
    q_t[t] * soldier_cost[res_name] <= r[res_name, t]
)

# Restrição mínima de soldados
@constraint(model, q >= 100)

# Armazém aumenta capacidade para madeira, barro e ferro
warehouse_idx = findfirst(==("Warehouse"), buildings)
@constraint(model, [t in 1:T],
    w["Wood",t] == 800 + 800*sum(n[warehouse_idx,l,t] for l in levels))
@constraint(model, [t in 1:T],
    w["Clay",t] == 800 + 800*sum(n[warehouse_idx,l,t] for l in levels)) 
@constraint(model, [t in 1:T],
    w["Iron",t] == 800 + 800*sum(n[warehouse_idx,l,t] for l in levels))

# Celeiro aumenta capacidade para cereal
granary_idx = findfirst(==("Granary"), buildings)
@constraint(model, [t in 1:T],
    w["Crop",t] == 800 + 800*sum(n[granary_idx,l,t] for l in levels))

# Limite de 3 construções simultâneas
for t in 1:T
    @constraint(model, sum(
        x[s,l,τ] for s in eachindex(buildings), l in levels,
        τ in max(1, t - Int(floor(building_times[buildings[s]][l])) + 1):t
    ) <= 3)
end

# Função objetivo
@objective(model, Max, sum(
    n[s_idx, l, T] * population[buildings[s_idx]][l] 
    for s_idx in eachindex(buildings), l in levels
))

# Resolver o modelo
optimize!(model)

# Exibir resultados
if termination_status(model) == MOI.OPTIMAL
    println("\n=== SOLUÇÃO ÓTIMA ENCONTRADA ===")
    
    # População total
    total_pop = sum(value.(total_population[t]) for t in 1:T)
    println("\nPopulação total acumulada: ", total_pop)
    
    # Soldados treinados
    println("Soldados treinados: ", value(q))
    
    # Recursos finais
    println("\nRecursos finais:")
    for r in eachindex(resources)
        println("  $(resources[r]): ", value(r[r, end]))
    end
    
    # Construções realizadas
    println("\nConstruções realizadas:")
    for s in eachindex(buildings)
        built = false
        for l in 1:20, t in 1:T
            if value(x[s, l, t]) > 0.5
                println("  $(buildings[s]) - Nível $l iniciado no tempo $t")
                built = true
                break
            end
        end
        if !built
            println("  $(buildings[s]) - Não construído")
        end
    end
    
    # Níveis finais das construções
    println("\nNíveis finais das construções:")
    for s in eachindex(buildings)
        max_level = 0
        for l in 20:-1:1
            if value(n[s, l, end]) > 0.5
                max_level = l
                break
            end
        end
        println("  $(buildings[s]): Nível $max_level")
    end
    
    # Evolução da população
    println("\nEvolução da população (amostra a cada 12 horas):")
    for t in 1:12:T
        println("  Tempo $t (≈ $(t/3600) horas): População = ", round(Int, value(total_population[t])))
    end
    
else
    println("Não foi possível encontrar uma solução ótima.")
    println("Status: ", termination_status(model))
end