#include "helpers.h"
#include <spawn.h>
#include <sys/wait.h>

extern char **environ;

bool secure_exec(char *command, struct env_vars* env_vars) {
    if (!command || strlen(command) == 0) {
        return false;
    }
    
    pid_t pid;
    char *args[] = {"/bin/sh", "-c", command, NULL};
    posix_spawn_file_actions_t file_actions;
    posix_spawnattr_t attr;
    
    posix_spawnattr_init(&attr);
    posix_spawn_file_actions_init(&file_actions);
    
    char **envp = environ;
    size_t env_count = 0;
    
    if (env_vars && env_vars->count > 0) {
        while (environ[env_count]) env_count++;
        
        envp = malloc(sizeof(char*) * (env_count + env_vars->count + 1));
        if (!envp) {
            posix_spawnattr_destroy(&attr);
            posix_spawn_file_actions_destroy(&file_actions);
            return false;
        }
        
        for (size_t i = 0; i < env_count; i++) {
            envp[i] = environ[i];
        }
        
        for (int i = 0; i < env_vars->count; i++) {
            size_t key_len = strlen(env_vars->vars[i]->key);
            size_t val_len = strlen(env_vars->vars[i]->value);
            char *env_entry = malloc(key_len + val_len + 2);
            if (env_entry) {
                snprintf(env_entry, key_len + val_len + 2, "%s=%s", 
                        env_vars->vars[i]->key, env_vars->vars[i]->value);
                envp[env_count + i] = env_entry;
            }
        }
        envp[env_count + env_vars->count] = NULL;
    }
    
    int result = posix_spawn(&pid, "/bin/sh", &file_actions, &attr, args, envp);
    
    if (envp != environ) {
        for (int i = 0; i < env_vars->count; i++) {
            if (envp[env_count + i]) {
                free(envp[env_count + i]);
            }
        }
        free(envp);
    }
    
    posix_spawnattr_destroy(&attr);
    posix_spawn_file_actions_destroy(&file_actions);
    
    if (result != 0) {
        return false;
    }
    
    int status;
    waitpid(pid, &status, 0);
    return WIFEXITED(status) && WEXITSTATUS(status) == 0;
}

char* cfstring_get_cstring(CFStringRef text_ref) {
  CFIndex length = CFStringGetLength(text_ref);
  uint32_t size = CFStringGetMaximumSizeForEncoding(length,
                                                    kCFStringEncodingUTF8);
  char* buf = malloc(sizeof(char)*(size + 1)); 
  CFStringGetCString(text_ref, buf, size + 1, kCFStringEncodingUTF8);
  return buf;
}

char* string_copy(char* s) {
  int length = strlen(s);
  char* result = malloc(length + 1);
  if (!result) return NULL;

  memcpy(result, s, length);
  result[length] = '\0';
  return result;
}

const char* get_name_for_pid(uint64_t pid) {
  return [[[NSRunningApplication runningApplicationWithProcessIdentifier:pid] localizedName] UTF8String];
}

const char* read_file(char* path) {
  struct stat buffer;

  if (stat(path, &buffer) != 0 || buffer.st_mode & S_IFDIR)
    return NULL;

  int fd = open(path, O_RDONLY);
  int len = lseek(fd, 0, SEEK_END);
  char* file = mmap(0, len, PROT_READ, MAP_PRIVATE, fd, 0);
  close(fd);

  return string_copy(file);
}

