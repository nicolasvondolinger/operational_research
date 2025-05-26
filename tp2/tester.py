import os
import subprocess
import sys

def test_code(cpp_file="main.cpp", input_dir="judge", output_file="out.txt"):
    # Compila o código C++
    compile_command = f"g++ -O3 {cpp_file} -o main"
    print(f"Compilando: {compile_command}")
    compile_result = subprocess.run(compile_command, shell=True)
    
    if compile_result.returncode != 0:
        print("Erro na compilação!")
        return False
    
    # Verifica se o diretório judge existe
    if not os.path.exists(input_dir):
        print(f"Erro: Diretório '{input_dir}' não encontrado!")
        print("Certifique-se que existe um diretório 'judge' com os arquivos de teste.")
        return False
    
    # Cria lista de arquivos de entrada e saída esperada
    test_cases = []
    for i in range(1, 11):
        input_file = os.path.join(input_dir, f"example{i:02d}.txt")
        expected_output_file = os.path.join(input_dir, f"sol_example{i:02d}.txt")
        
        if os.path.exists(input_file) and os.path.exists(expected_output_file):
            test_cases.append((input_file, expected_output_file))
        else:
            print(f"Aviso: Par de arquivos para teste {i:02d} não encontrado")
    
    if not test_cases:
        print("Erro: Nenhum caso de teste completo encontrado!")
        print("Certifique-se que existem arquivos entradaXX.txt e sol_exampleXX.txt no diretório judge")
        return False
    
    print(f"\nEncontrados {len(test_cases)} casos de teste válidos")
    
    # Testa cada caso
    all_passed = True
    for input_file, expected_output_file in test_cases:
        print(f"\nTestando com entrada: {os.path.basename(input_file)}")
        
        # Executa o programa com a entrada
        try:
            with open(input_file, 'r') as infile, open(output_file, 'w') as outfile:
                subprocess.run(["./main", input_file], stdin=infile, stdout=outfile, check=True)
        except subprocess.CalledProcessError as e:
            print(f"Erro ao executar o programa com a entrada {input_file}")
            print(f"Código de erro: {e.returncode}")
            all_passed = False
            continue
        
        # Compara com a saída esperada
        try:
            with open(output_file, 'r') as outfile, open(expected_output_file, 'r') as solfile:
                output_lines = outfile.readlines()
                expected_lines = solfile.readlines()
                
                # Remove espaços em branco no final de cada linha para comparação
                output_lines = [line.rstrip() for line in output_lines]
                expected_lines = [line.rstrip() for line in expected_lines]
                
                if output_lines == expected_lines:
                    print(f"✅ Teste {os.path.basename(input_file)} passou!")
                else:
                    print(f"❌ Teste {os.path.basename(input_file)} falhou!")
                    print("Diferenças encontradas:")
                    for i, (out_line, exp_line) in enumerate(zip(output_lines, expected_lines)):
                        if out_line != exp_line:
                            print(f"Linha {i+1}:")
                            print(f"  Esperado: {exp_line}")
                            print(f"  Obtido:   {out_line}")
                    all_passed = False
        except FileNotFoundError as e:
            print(f"Erro ao ler arquivos de saída: {e}")
            all_passed = False
    
    return all_passed

if __name__ == "__main__":
    cpp_file = sys.argv[1] if len(sys.argv) > 1 else "main.cpp"
    if test_code(cpp_file):
        print("\nTodos os testes passaram!")
        sys.exit(0)
    else:
        print("\nAlguns testes falharam!")
        sys.exit(1)