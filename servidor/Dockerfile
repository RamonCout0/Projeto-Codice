# Imagem do servidor da NAVICity, em dois estágios.
#
# 1º estágio: a imagem golang (~380 MB) compila o binário.
# 2º estágio: só o binário vai para uma imagem vazia (scratch), que fica com
# poucos MB. Funciona porque, com CGO_ENABLED=0, o Go gera um executável
# estático, que não depende de nenhuma biblioteca do sistema.
FROM golang:1.27-alpine AS compilacao
WORKDIR /src
COPY go.mod ./
COPY cmd ./cmd
COPY internal ./internal
# O cache de build do BuildKit acelera recompilações sem entrar na imagem.
RUN --mount=type=cache,target=/root/.cache/go-build \
    CGO_ENABLED=0 go build -trimpath -ldflags="-s -w" -o /navicity-server ./cmd/navicity-server

FROM scratch
COPY --from=compilacao /navicity-server /navicity-server
# Usuário sem privilégios (nobody). Mesmo dentro do container, não rodar como root.
USER 65534:65534
ENTRYPOINT ["/navicity-server"]
