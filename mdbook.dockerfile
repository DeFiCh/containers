FROM docker.io/rust:1
RUN cargo install mdbook mdbook-toc mdbook-mermaid mdbook-plantuml
