FROM rockylinux:9

RUN dnf -y update

# Slurm
RUN dnf -y install epel-release && \
    dnf -y install slurm munge sudo
COPY --from=slurm slurm.conf /etc/slurm/
COPY --from=munge --chown=munge:munge munge.key /etc/munge/

ARG GITHUB_UID
RUN useradd --no-log-init -u $GITHUB_UID github
RUN dnf -y install perl-HTTP-Server-Simple perl-JSON
COPY github_meta_runner entrypoint.sh job.sbatch /opt/

RUN dnf clean all

ENTRYPOINT /opt/entrypoint.sh

