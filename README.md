# No-Prep Racing Simulator — Incremento I01

Protótipo inicial de arrancada **No-Prep em 201 metros** construído em **Godot 4.7.2**, com visual 3D provisório e simulação própria separada da apresentação.

**Não é um produto oficial Armageddon e não utiliza marcas ou assets do evento.**

## Abrir

1. Instale **Godot Engine 4.7.2 Standard** (GDScript; não é necessário .NET).
2. Abra o Godot → **Importar** → selecione `project.godot`.
3. Abra `scenes/main.tscn` e pressione **F6**, ou pressione **F5** para iniciar o jogo.
4. Pressione **ESPAÇO** para o pinheiro fazer a contagem e **W** para acelerar **após o verde**.

A simulação usa a frequência de **120 ticks de física/segundo** e uma pista de 201 metros.

## Controles (desktop)

| Tecla | Ação |
| --- | --- |
| ESPAÇO | Iniciar contagem de largada |
| W / S ou setas ↑ / ↓ | Acelerar progressivamente / frear |
| A / D ou setas ← / → | Direção manual |
| E / Q | Subir / reduzir marcha |
| X / Z | Aumentar / reduzir pressão do turbo (2 psi) |
| V / C | Aumentar / diminuir aderência do pneu (`μ` em 0,05) |
| R | Reiniciar carro, contagem e cronometragem |

Dicas: segurar W antes do verde queima a largada. A potência plena em uma pista de baixa aderência pode ser pior que uma aceleração controlada. Para testar isso, faça puxadas variando o turbo e a forma de acelerar.

## O que já existe no código

- Um veículo fictício, com torque versus RPM, turbo ajustável, quatro marchas, diferencial e perdas mecânicas.
- Balanço longitudinal com arrasto, rolamento e transferência aproximada de carga para o eixo traseiro.
- Limite de força de pneu pela aderência e perda adicional de tração quando há patinagem excessiva.
- Movimento lateral e guinada simplificados por direção manual.
- Cenário 3D provisório gerado com primitivas (sem assets externos).
- Pista 201 m, semáforo de largada, tempo de reação, tempo decorrido e indicação de cruzamento de centerline.
- Testes de regressão para torque, aderência, deslocamento, mudanças de marcha, estabilidade de cálculo e regras de corrida.

## Limitações **explícitas** do I01

- **Modelo de pneus é empírico**, não resolve a força longitudinal de cada pneu nem simula rotação independente das rodas/embreagem.
- A direção usa **modelo simplificado de bicicleta**, sem dinâmica de derrapagem lateral, contatos de parede ou colisões.
- O tempo de reação começa no verde e acaba com movimento > 0,2 m/s; o ET começa nesse limiar. **Ainda não há feixe de staging/rollout homologável**.
- A pista e o carro são provisórios e não têm animações sofisticadas, sons ou assets de terceiros.
- Os ajustes de turbo e aderência são de **teste em execução** e **não são persistidos**; garagem e persistência são prioridade do I03.
- Controle por teclado e desktop apenas neste incremento; mobile e gamepad requerem UX própria.
- Sem contas, multiplayer, listas, rankings e backend.
- A execução dos testes no Godot exige a instalação local do engine ou CI GitHub; a presença dos scripts por si só não comprova aprovação.

## Testes

Após importar o projeto, execute no terminal na pasta do projeto:

```bash
godot --headless --path . --script res://tests/run_tests.gd
```

O teste imprime `RESULT: N checks, 0 failures` e encerra com código 0 em caso de sucesso. O workflow `.github/workflows/godot-tests.yml` executa importação e testes em push/PR quando o projeto estiver num repositório GitHub.

## Estrutura

```text
scenes/main.tscn
scripts/main.gd                  # Controles, câmera e HUD
scripts/simulation/vehicle_config.gd
scripts/simulation/vehicle_simulator.gd
scripts/race/race_session.gd
scripts/visuals/track_builder.gd
scripts/visuals/vehicle_builder.gd
tests/run_tests.gd
.github/workflows/godot-tests.yml
docs/DECISIONS.md
```

## Próximo incremento

I02: refinar largada, staging/rollout e detecção de invasão, aprimorar o controle da transmissão e o desempenho gráfico. Só depois evoluir para garagem, presets de preparação e telemetria comparativa.
