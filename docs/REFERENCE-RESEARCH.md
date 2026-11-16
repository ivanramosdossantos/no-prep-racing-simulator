# Análise de referência — conceitos para o No-Prep

## Material estudado
Arquivo app-dragrace-main.zip: estudo estático de engenharia reversa de No Limit Drag Racing 2, incluindo README e documentos de física, personalização, telas e assets. O ZIP não é um projeto Unity jogável e não oferece assets com licença de reutilização.

## O que aprendemos como princípios de design
1. O ciclo de jogo precisa diferenciar preparar, alinhar, largar, pilotar e analisar.
2. Burnout pode afetar uma condição dos pneus e, por consequência, o desempenho.
3. Uma transmissão e a curva do motor devem determinar uma faixa de rotação útil.
4. Câmeras, fumaça e rotação de rodas reforçam a percepção de movimento.
5. Garagem precisa integrar visualização, preparação mecânica e feedback.
6. Jogos de corrida comerciais utilizam modelos de física e assistências empíricas, não só números visuais.

## Adaptação independente
No I02, implementamos nossa própria curva empírica de calor/aderência e novos feedbacks de pilotagem. Nenhuma constante, algoritmo decompilado, código binário, textura, modelo, imagem ou marca comercial foi copiado.

## Pendências
- Teste interativo de câmera e HUD em 16:9 e mobile.
- Áudio e veículo 3D próprio ou licenciado de terceiros.
- Staging real com pré-stage/stage e rollout por sensores.
- Burnout com forças e temperatura por pneu, caso o modelo empírico se revele insuficiente.
- Calibração por referência observacional real (ET, velocidades, telemetria).
