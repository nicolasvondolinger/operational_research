using Gurobi

# Função para resolver o modelo
function modelo_travian()
    # Inicialização do modelo
    model = Model(Gurobi.Optimizer)
    
    # Definindo variáveis de decisão
    # x[s, l, t] binária: se o nível l da construção s foi iniciado no tempo t
    @variable(model, x[s, l, t] in Bin)
    
    # n[s, l, t] inteira: quantidade de níveis l da construção s completos até o tempo t
    @variable(model, n[s, l, t] >= 0, Int)
    
    # r[r, t] quantidade de recursos r disponíveis no tempo t
    @variable(model, r[r, t] >= 0, Int)
    
    # q_t número de soldados treinados até o tempo t
    @variable(model, q_t[t] >= 0, Int)
    
    # q número total de soldados treinados
    @variable(model, q >= 0, Int)
    
    # Função objetivo
    @objective(model, Max, q)
    
    # Restrições
    # Restrição 1: Construção ´unica por n´ıvel
    @constraint(model, sum(x[s, l, t] for t in 1:T) <= 1 for s in constructions, l in levels)
    
    # Restrição 2: Apenas um edifício de cada tipo (exceto campos de recurso)
    @constraint(model, sum(x[s, l, t] for l in levels, t in 1:T) == 1 for s in buildings)
    
    # Restrição 3: Disponibilidade de recursos (em cada tempo t)
    @constraint(model, r[r, t] <= storage_capacity[r] for r in resources, t in 1:T)
    
    # Restrição 4: Requisitos de construção (campos de recurso)
    @constraint(model, sum(x[s, l, t] * resource_required[s, l] for s in constructions, l in levels, t in 1:T) <= r[r, t] for r in resources, t in 1:T)
    
    # Restrição 5: O quartel deve existir antes de treinar soldados
    @constraint(model, sum(x["Quartel", l, t] for l in levels, t in 1:T) >= 1) 
    
    # Restrição 6: Recursos suficientes para treinamento de soldados
    @constraint(model, sum(q_t[t] * soldier_cost[t] for t in 1:T) <= sum(r[r, t] for r in resources, t in 1:T))
    
    # Restrição 7: Quantidade mínima de soldados
    @constraint(model, q >= 100)
    
    # Restrições adicionais podem ser incluídas aqui
    
    # Resolver o modelo
    optimize!(model)
    
    # Verificar status de solução
    if termination_status(model) == MOI.OPTIMAL
        println("Solução ótima encontrada!")
        println("Número total de soldados: ", value(q))
    else
        println("Não foi possível encontrar uma solução ótima.")
    end
end

constructions = []  # Lista das construções
levels = []  # Níveis das construções
T = 72  # Horizonte de 72h
buildings = []  # Tipos de edifícios
resources = []  # Tipos de recursos
storage_capacity = Dict()  # Capacidade de armazenamento de cada recurso
resource_required = Dict()  # Requisitos de recursos para cada construção
soldier_cost = []  # Custo para treinar soldados

# Chamar a função
modelo_travian()
