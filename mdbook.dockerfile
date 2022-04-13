FROM docker.io/rust
RUN cargo install mdbook mdbook-toc mdbook-mermaid mdbook-plantuml 
