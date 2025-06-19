#!/usr/bin/perl
use strict;
use warnings;
use File::Basename;
use Cwd 'abs_path';

# Configurações
my $config = {
    brew_cellar    => "/home/linuxbrew/.linuxbrew/Cellar/glib",
    target_lib_dir => "/usr/local/lib",
    lib_patterns   => [
        qr/^libglib-2\.0/,
        qr/^libgobject-2\.0/,
        qr/^libgio-2\.0/,
        qr/^libgmodule-2\.0/,
        qr/^libgthread-2\.0/,
        qr/^libgirepository-2\.0/,
    ],
    pkgconfig_dir => "pkgconfig",
};

# --- Validações iniciais ---
validate_environment($config);

# --- Encontra a versão mais recente do glib ---
my $latest_version = find_latest_version($config->{brew_cellar});
my $lib_source_dir = "$latest_version/lib";

# --- Processamento dos links ---
print "Atualizando links para bibliotecas do glib $latest_version...\n";

# Atualiza links das bibliotecas
update_library_links($lib_source_dir, $config->{target_lib_dir}, $config);

# Atualiza links do pkgconfig se existir
if (-d "$lib_source_dir/$config->{pkgconfig_dir}") {
    update_pkgconfig_links("$lib_source_dir/$config->{pkgconfig_dir}", 
                         "$config->{target_lib_dir}/pkgconfig");
}

print "Links de bibliotecas atualizados com sucesso!\n";

# --- Subrotinas ---
sub validate_environment {
    my ($config) = @_;
    
    unless (-d $config->{brew_cellar}) {
        die "Erro: Diretório do glib não encontrado em $config->{brew_cellar}.\n";
    }
    
    unless (-w $config->{target_lib_dir} || $< == 0) {
        die "Erro: Sem permissão para escrever em $config->{target_lib_dir}. Execute com sudo.\n";
    }
}

sub find_latest_version {
    my ($brew_cellar) = @_;
    
    my @versions = glob("$brew_cellar/*");
    die "Erro: Nenhuma versão do glib encontrada.\n" unless @versions;
    
    @versions = sort { versioncmp($a, $b) } @versions;
    return $versions[-1];
}

sub versioncmp {
    my ($a, $b) = @_;
    $a =~ s/[^\d.]//g;
    $b =~ s/[^\d.]//g;
    return $a <=> $b;
}

sub update_library_links {
    my ($source_dir, $target_dir, $config) = @_;
    
    opendir(my $dh, $source_dir) or die "Não foi possível abrir $source_dir: $!";
    
    while (my $entry = readdir($dh)) {
        next unless -f "$source_dir/$entry";  # Apenas arquivos
        
        # Verifica se o arquivo corresponde a algum dos padrões de biblioteca
        my $is_lib = 0;
        foreach my $pattern (@{$config->{lib_patterns}}) {
            if ($entry =~ $pattern) {
                $is_lib = 1;
                last;
            }
        }
        next unless $is_lib;
        
        my $source = "$source_dir/$entry";
        my $target = "$target_dir/$entry";
        
        # Se for um link simbólico, remove o existente primeiro
        if (-l $target) {
            unlink($target) or warn "Aviso: Não pude remover link existente $target: $!\n";
        }
        
        create_symlink($source, $target);
    }
    
    closedir($dh);
}

sub update_pkgconfig_links {
    my ($source_pkg_dir, $target_pkg_dir) = @_;
    
    # Cria o diretório de pkgconfig se não existir
    unless (-d $target_pkg_dir) {
        system("sudo", "mkdir", "-p", $target_pkg_dir) == 0 or
            warn "Aviso: Não pude criar diretório $target_pkg_dir: $!\n";
    }
    
    opendir(my $dh, $source_pkg_dir) or return;  # Se falhar, ignora
    
    while (my $entry = readdir($dh)) {
        next unless $entry =~ /\.pc$/;  # Apenas arquivos .pc
        
        my $source = "$source_pkg_dir/$entry";
        my $target = "$target_pkg_dir/$entry";
        
        create_symlink($source, $target);
    }
    
    closedir($dh);
}

sub create_symlink {
    my ($source, $target) = @_;
    
    if (system("sudo", "ln", "-sf", $source, $target) != 0) {
        warn "Aviso: Falha ao criar link de $source para $target: $!\n";
        return 0;
    }
    print "Criado link: $target -> $source\n";
    return 1;
}
