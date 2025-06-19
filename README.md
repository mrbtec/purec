GLib Link Manager
Objetivo

Este conjunto de scripts Perl foi desenvolvido para automatizar a gestão de links simbólicos para arquivos de desenvolvimento do GLib (headers e bibliotecas) em sistemas onde o GLib é instalado via Homebrew (Linuxbrew).
Problema Resolvido

Quando o GLib é reinstalado ou atualizado via brew reinstall glib ou brew upgrade glib:

    Os arquivos são instalados em diretórios versionados (ex: /home/linuxbrew/.linuxbrew/Cellar/glib/2.84.3/)

    Os links existentes para headers e bibliotecas tornam-se inválidos

    Projetos de desenvolvimento e sistemas de compilação deixam de encontrar os arquivos necessários

Estes scripts resolvem esse problema automaticamente, atualizando todos os links necessários para apontar para a versão mais recente instalada.
Scripts Incluídos

    update_glib_headers.pl - Atualiza links para headers:

        glib.h, glib-object.h, glib-unix.h, etc.

        Diretórios como gobject, gio, gmodule

    update_glib_libs.pl - Atualiza links para bibliotecas:

        libglib-2.0, libgobject-2.0, libgio-2.0, etc.

        Arquivos .so, .a e versões específicas

        Arquivos do pkgconfig (.pc)

Benefícios

    Automatização completa: Elimina a necessidade de atualizar links manualmente

    Segurança: Verifica existência de arquivos antes de criar links

    Robustez: Tratamento adequado de erros e permissões

    Flexibilidade: Fácil adaptação para outras bibliotecas

Pré-requisitos

    Perl 5.x instalado

    Homebrew/Linuxbrew instalado e configurado

    Permissões de superusuário (para criar links em /usr/local/)

Como Usar

    Dê permissão de execução aos scripts:
    bash

chmod +x update_glib_*.pl

Execute os scripts com sudo:
bash

    sudo ./update_glib_headers.pl
    sudo ./update_glib_libs.pl

    (Opcional) Agende execução pós-atualização do brew

Personalização

Para adaptar para outras bibliotecas:

    Edite as variáveis de configuração no início de cada script

    Ajuste os padrões de nomes de arquivos conforme necessário

Melhorias Futuras

    Adicionar suporte a dry-run (simulação)

    Implementar backup de links existentes

    Adicionar opção para remoção de links obsoletos

    Empacotar como fórmula Homebrew

Licença

Distribuído sob licença MIT.
