#!/usr/bin/perl
use strict;
use warnings;
use File::Basename;
use Cwd 'abs_path';

# Configurações globais
my $config = {
    brew_cellar     => "/home/linuxbrew/.linuxbrew/Cellar/glib",  # Caminho do Homebrew
    target_include  => "/usr/local/include",                     # Destino dos headers
    target_lib      => "/usr/local/lib",                         # Destino das libs
    required_dirs   => [qw(gobject gio gmodule)],                # Subdiretórios obrigatórios
    header_files    => [qw(glib.h glib-object.h glib-unix.h gmodule.h)],
    lib_patterns    => [                                         # Padrões de bibliotecas
        qr/^libglib-2\.0/, qr/^libgobject-2\.0/,
        qr/^libgio-2\.0/, qr/^libgmodule-2\.0/,
        qr/^libgthread-2\.0/, qr/^libgirepository-2\.0/
    ],
    pkgconfig_dir  => "pkgconfig",                               # Diretório pkgconfig
};

### --- Validação inicial ---
validate_environment($config);

### --- Detecta a versão mais recente do GLib ---
my $latest_version = find_latest_version($config->{brew_cellar});
my $source_include = "$latest_version/include/glib-2.0";
my $source_lib     = "$latest_version/lib";

### --- Atualização dos links ---
print "Atualizando links para GLib $latest_version...\n";

# Atualiza headers (.h)
update_headers($source_include, $config->{target_include}, $config);

# Atualiza bibliotecas (.so, .a)
update_libraries($source_lib, $config->{target_lib}, $config);

# Atualiza pkgconfig (se existir)
update_pkgconfig("$source_lib/$config->{pkgconfig_dir}", "$config->{target_lib}/pkgconfig");

print "✅ Todos os links foram atualizados com sucesso!\n";

### --- Subrotinas ---
sub validate_environment {
    my ($conf) = @_;
    die "Erro: Homebrew GLib não encontrado em $conf->{brew_cellar}.\n" unless -d $conf->{brew_cellar};
    die "Erro: Sem permissão em $conf->{target_include} ou $conf->{target_lib}.\nExecute com sudo.\n" 
        unless (-w $conf->{target_include} && -w $conf->{target_lib}) || $< == 0;
}

sub find_latest_version {
    my ($path) = @_;
    my @versions = sort { versioncmp($a, $b) } glob("$path/*");
    die "Erro: Nenhuma versão do GLib encontrada.\n" unless @versions;
    return $versions[-1];  # Retorna a versão mais recente
}

sub versioncmp {
    my ($a, $b) = @_;
    $a =~ s/[^\d.]//g; $b =~ s/[^\d.]//g;
    return $a <=> $b;
}

sub update_headers {
    my ($src_dir, $target_dir, $conf) = @_;
    die "Erro: Diretório include não encontrado: $src_dir\n" unless -d $src_dir;

    # Links para arquivos .h
    foreach my $file (@{$conf->{header_files}}) {
        my $source = "$src_dir/$file";
        next unless -f $source;
        create_symlink($source, "$target_dir/$file");
    }

    # Links para subdiretórios (gobject, gio, etc.)
    foreach my $dir (@{$conf->{required_dirs}}) {
        my $source = "$src_dir/$dir";
        next unless -d $source;
        create_symlink($source, "$target_dir/$dir");
    }
}

sub update_libraries {
    my ($src_dir, $target_dir, $conf) = @_;
    opendir(my $dh, $src_dir) or die "Erro ao ler $src_dir: $!\n";

    while (my $entry = readdir($dh)) {
        next unless -f "$src_dir/$entry";
        my $is_lib = grep { $entry =~ $_ } @{$conf->{lib_patterns}};
        next unless $is_lib;
        create_symlink("$src_dir/$entry", "$target_dir/$entry");
    }
    closedir($dh);
}

sub update_pkgconfig {
    my ($src_pkg, $target_pkg) = @_;
    return unless -d $src_pkg;
    system("sudo", "mkdir", "-p", $target_pkg) unless -d $target_pkg;

    opendir(my $dh, $src_pkg) or return;
    while (my $entry = readdir($dh)) {
        next unless $entry =~ /\.pc$/;
        create_symlink("$src_pkg/$entry", "$target_pkg/$entry");
    }
    closedir($dh);
}

sub create_symlink {
    my ($src, $target) = @_;
    system("sudo", "ln", "-sf", $src, $target) == 0
        or warn "⚠️ Falha ao criar link: $target → $src ($!)\n";
}
