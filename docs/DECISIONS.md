# Registro de decisões — No-Prep I01

- **ADR-001**: usar Godot 4.7.2 Standard com GDScript e renderizador Compatibility; versão estável atual em 16/11/2026.
- **ADR-002**: não usar `VehicleBody3D` como fonte da física; cálculos do veículo em `NoPrepVehicleSimulator`, que recebe entradas e avança com passo fixo.
- **ADR-003**: protótipo possui carro fictício e pista sem marcas oficiais de terceiros.
- **ADR-004**: sem servidor neste incremento; futuras Listas e multiplayer exigirão validação autoritativa.
- **ADR-005**: configuração mecânica e resultados em memória no I01. Persistência de presets virá na garagem.
- **ADR-006**: simulação com aproximações empíricas de patinagem, launch-clutch e direção; não declarar equivalência com dinamômetro, célula de carga ou cronometragem oficial.
- **ADR-007**: corridas de 201 m, direção, acelerador e trocas manuais, nunca usar aceleração apenas cinematográfica.

## Critérios de aceite principais

- Abrir a cena, iniciar contagem com ESPAÇO e completar uma puxada de 201 m usando troca manual.
- Pressionar aceleração antes do verde resulta em red light.
- Aceleração, patinagem e resultado são calculados pelo mesmo núcleo, independentemente da taxa de renderização.
- Modificar aderência e torque impacta cálculos, comprovável em testes.
- Testes executados em engine e projeto importado sem erros antes de declarar I01 aprovado.
