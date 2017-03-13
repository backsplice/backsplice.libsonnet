local kubeAssert = import "./assert.libsonnet";
local base = import "./base.libsonnet";

{
  local Kind(kind) = kubeAssert.Type("kind", kind, "string") {
    kind: kind,
  },

  v1:: {
    local bases = {
      ConfigMap: base.New("configMap", "AC74E727-0605-4872-8F30-E5CAFB2A0984"),
      Container: base.New("container", "50281784-097C-46A9-8D2C-C6E9078D77D4"),
      ContainerPort:
        base.New("containerPort", "2854EB13-644C-4FEF-A62D-DBAC554D6A24"),
      PersistentVolume:
        base.New("persistentVolume", "03113473-7083-4D07-A7FE-83699EB4128C"),
      PersistentVolumeClaim:
        base.New("persistentVolumeClaim", "CD58B997-FF5E-4ED9-8F8A-573E92336D35"),
      Pod: base.New("pod", "2854EB13-644C-4FEF-A62D-DBAC554D6A24"),
      Probe: base.New("probe", "943CF775-B17F-4D25-A794-7D800F08E7FE"),
      Secret: base.New("secret", "0C3D2362-968B-4751-BF67-D58ADA1FC5FC"),
      Service: base.New("service", "87EE499C-EC06-421D-9450-EFE0701851EB"),
      ServicePort: base.New("servicePort", "C38839B7-DA05-4845-B643-E6826E38EA1B"),
      Mount: base.New("mount", "D1E2E601-E64A-4A95-A15C-E78CA724764C"),
      Namespace: base.New("namespace", "6A94A118-F6A7-40EE-8BA1-6096CEC7BDE3"),
    },

    local ApiVersion = { apiVersion: "v1" },

    //
    // Namespace.
    //

    namespace:: {
      Default(name)::
        bases.Namespace +
        kubeAssert.Type("name", name, "string") +
        ApiVersion +
        Kind("Namespace") {
          metadata: $.v1.metadata.Name(name)
        },
    },

    //
    // Ports.
    //
    port:: {
      local protocolOptions = std.set(["TCP", "UDP"]),

      local PortProtocol(protocol, targetBase) =
        kubeAssert.InSet("protocol", protocol, protocolOptions) +
        base.Verify(targetBase) {
          protocol: protocol,
        },

        local PortName(name, targetPort) =
          base.Verify(targetPort) +
          kubeAssert.Type("name", name, "string") {
            name: name,
          },

      container:: {
        Default(containerPort)::
          bases.ContainerPort +
          kubeAssert.ValidPort("containerPort", containerPort) {
            containerPort: containerPort,
          },

        Named(name, containerPort)::
          kubeAssert.Type("name", name, "string") +
          self.Default(containerPort) +
          self.Name(name),

        Name(name):: PortName(name, bases.ContainerPort),

        Protocol(protocol):: PortProtocol(protocol, bases.ContainerPort),

        HostPort(hostPort)::
          base.Verify(bases.ContainerPort) +
          kubeAssert.ValidPort("hostPort", hostPort) {
            hostPort: hostPort
          },

        HostIp(hostIp)::
          base.Verify(bases.ContainerPort) +
          kubeAssert.Type("hostIp", hostIp, "string") {
            hostIP: hostIp,
          },
      },

      service:: {
        Default(servicePort)::
          bases.ServicePort +
          kubeAssert.ValidPort("servicePort", servicePort) {
            port: servicePort,
          },

        Named(name, servicePort, targetPort)::
          kubeAssert.Type("name", name, "string") +
          self.Default(servicePort) +
          self.Name(name) +
          self.TargetPort(targetPort),

        Name(name):: PortName(name, bases.ServicePort),

        Protocol(protocol):: PortProtocol(protocol, bases.ServicePort),

        TargetPort(targetPort)::
          base.Verify(bases.ServicePort) {
            // TODO: Assert clusterIP is not set?
            targetPort: targetPort,
          },

        NodePort(nodePort)::
          base.Verify(bases.ServicePort) {
            nodePort: nodePort,
          },
      },
    },

    //
    // Service.
    //
    service:: {
      Default(metadata, portList):
        bases.Service + ApiVersion + Kind("Service") {
          metadata: metadata,
          spec: {
            ports: portList,
          },
        },

        //
        // Service spec.
        //

        local typeOptions = std.set([
          "ExternalName", "ClusterIP", "NodePort", "LoadBalancer"]),
        local sessionAffinityOptions = std.set(["ClientIP", "None"]),
        local specMixin(mixin) = { spec+: mixin },

        Selector(selector)::
          base.Verify(bases.Service) +
          specMixin({selector: selector}),

        ClusterIp(clusterIp)::
          base.Verify(bases.Service) +
          kubeAssert.Type("clusterIp", clusterIp, "string") +
          specMixin({clusterIP: clusterIp}),

        Type(type)::
          base.Verify(bases.Service) +
          kubeAssert.InSet("type", type, typeOptions) +
          specMixin({type: type}),

        ExternalIps(externalIpList)::
          base.Verify(bases.Service) +
          // TODO: Verify that externalIpList is a list of string.
          kubeAssert.Type("externalIpList", externalIpList, "array") +
          specMixin({externalIPs: externalIpList}),

        SessionAffinity(sessionAffinity)::
          base.Verify(bases.Service) +
          kubeAssert.InSet(
            "sessionAffinity", sessionAffinity, sessionAffinityOptions) +
          specMixin({sessionAffinity: sessionAffinity}),

        LoadBalancerIp(loadBalancerIp)::
          base.Verify(bases.Service) +
          kubeAssert.Type("loadBalancerIp", loadBalancerIp, "string") +
          specMixin({loadBalancerIP: loadBalancerIp}),

        LoadBalancerSourceRanges(loadBalancerSourceRanges)::
          base.Verify(bases.Service) +
          // TODO: Verify that loadBalancerSourceRanges is a list of string.
          kubeAssert.Type(
            "loadBalancerSourceRanges", loadBalancerSourceRanges, "array") +
          specMixin({loadBalancerSourceRanges: loadBalancerSourceRanges}),

        ExternalName(externalName)::
          base.Verify(bases.Service) +
          kubeAssert.Type("externalName", externalName, "string") +
          specMixin({externalName: externalName}),
    },

    configMap:: {
      Default(namespace, configMapName, data):
        bases.ConfigMap + ApiVersion + Kind("ConfigMap") {
          metadata:
            $.v1.metadata.Name(configMapName) +
            $.v1.metadata.Namespace(namespace),
          data: data,
        },

      DefaultFromClaim(namespace, name, claim)::
        self.Default(namespace, name, claim.metadata.name)
    },

    secret:: {
      Default(namespace, configMapName, data)::
        bases.Secret + ApiVersion + Kind("Secret") {
          metadata:
            $.v1.metadata.Name(configMapName) +
            $.v1.metadata.Namespace(namespace),
          data: data,
        },

      StringData(stringData)::
        base.Verify(bases.Secret) {
          stringData: stringData,
        },

      Type(type)::
        base.Verify(bases.Secret) +
        kubeAssert.Type("type", type, "string") {
          type: type,
        },
    },

    //
    // Volume.
    //

    //
    // NOTE: TODO: YOU ARE HERE. You haven't implemented type checking
    // beyond this point.
    //

    volume:: {
      persistent:: {
        Default(name, claimName):: bases.PersistentVolume {
          name: name,
          persistentVolumeClaim: {
            claimName: claimName,
          },
        },

        DefaultFromClaim(name, claim)::
          self.Default(name, claim.metadata.name)
      },

      // TODO: It is confusing that there is one of these in `v1` and
      // `v1.volume`.
      // TODO: Add a check here.
      configMap:: {
        Default(name, configMapName):: {
          name: name,
          configMap: {
            name: configMapName,
          },
        },
      },

      EmptyDir(name):: {
        name: name,
        emptyDir: {},
      },

      //
      // Mount.
      //
      mount:: {
        Default(name, mountPath, readOnly=false):: bases.Mount {
          name: name,
          mountPath: mountPath,
          readOnly: readOnly,
        },

        FromVolume(volume, mountPath, readOnly=false)::
          self.Default(volume.name, mountPath, readOnly),

        FromConfigMap(configMap, mountPath, readOnly=false)::
          self.Default(configMap.name, mountPath, readOnly),
      },

      //
      // Claim.
      //
      claim:: {
        DefaultPersistent(
          namespace,
          claimName,
          accessModes,
          size,
          storageClass="fast"
        ):
          bases.PersistentVolumeClaim +
          ApiVersion +
          Kind("PersistentVolumeClaim") {
            // TODO: Move this assert to `kubeAssert.Type`.
            assert std.type(accessModes) == "array"
              : "'accessModes' must by of type 'array'",
            metadata:
              $.v1.metadata.Name(claimName) +
              $.v1.metadata.Namespace(namespace) +
              $.v1.metadata.Annotations({
                "volume.beta.kubernetes.io/storage-class": storageClass,
              }),
            spec: {
              accessModes: accessModes,
              resources: {
                requests: {
                  storage: size
                },
              },
            },
          },
      },
    },

    //
    // Probe.
    //
    probe:: {
      Default(initDelaySecs, timeoutSecs):: bases.Probe {
        initialDelaySeconds: initDelaySecs,
        timeoutSeconds: timeoutSecs,
      },

      Http(getPath, portName, initDelaySecs, timeoutSecs)::
        self.Default(initDelaySecs, timeoutSecs) {
          httpGet: {
            path: getPath,
            port: portName,
          },
        },

      Tcp(port, initDelaySecs, timeoutSecs)::
        self.Default(initDelaySecs, timeoutSecs) {
          tcpSocket: {
            port: port,
          },
        },

      Exec(command, initDelaySecs, timeoutSecs)::
        self.Default(initDelaySecs, timeoutSecs) {
          exec: {
            command: command,
          },
        },
    },

    //
    // Container.
    //
    container:: {
      local imagePullPolicyOptions = std.set(["Always", "Never", "IfNotPresent"]),

      Default(name, image, imagePullPolicy="Always")::
        bases.Container +
        // TODO: Make "Always" the default only when we're doing the :latest.
        kubeAssert.Type("name", name, "string") +
        kubeAssert.Type("image", image, "string") +
        kubeAssert.InSet("imagePullPolicy", imagePullPolicy, imagePullPolicyOptions) {
          name: name,
          image: image,
          imagePullPolicy: imagePullPolicy,
          // TODO: Think carefully about whether we want an empty list here.
          ports: [],
        },

      Command(command):: base.Verify(bases.Container) {
        command: command,
      },

      Env(env):: base.Verify(bases.Container) {
        env: env,
      },

      Ports(ports):: base.Verify(bases.Container) {
        ports: ports,
      },

      Port(port):: base.Verify(bases.Container) { ports+: [port] },

      NamedPort(name, port):: base.Verify(bases.Container) {
        ports+: [$.v1.port.container.Named(name, port)],
      },

      LivenessProbe(probe):: base.Verify(bases.Container) {
        livenessProbe: probe,
      },

      ReadinessProbe(probe):: base.Verify(bases.Container) {
        readinessProbe: probe,
      },

      VolumeMounts(mounts):: base.Verify(bases.Container) {
        volumeMounts: mounts,
      },
    },

    //
    // Env.
    //
    env:: {
      Variable(name, value):: {
        name: name,
        value: value,
      },

      ValueFrom(name, configMapName, configMapKey):: {
        name: name,
        valueFrom: {
          configMapKeyRef: {
            name: configMapName,
            key: configMapKey,
          },
        },
      },

      ValueFromSecret(name, secretName, secretKey):: {
        name: name,
        valueFrom: {
          secretKeyRef: {
            name: secretName,
            key: secretKey,
          },
        },
      },
    },

    //
    // Metadata.
    //
    metadata:: {
      Name(name):: kubeAssert.Type("name", name, "string") {
        name: name,
      },

      Labels(labels):: {
        labels: labels,
      },

      Namespace(namespace)::
        kubeAssert.Type("namespace", namespace, "string") {
          namespace: namespace,
        },

      Annotations(annotations):: {
        annotations: annotations,
      },
    },

    //
    // Pods.
    //
    pod:: {
      Default(metadata, spec):: bases.Pod + ApiVersion + Kind("Pod") {
        metadata: metadata,
        spec: spec,
      },

      // TODO: Consider making this just a function on the pod itself.
      template:: {
        // TODO: This does not really belong here. We should have
        // something like `deployment.spec.Template` instead.
        Default(metadata, spec):: {
          metadata: metadata,
          spec: spec,
        },
      },

      // TODO: Consider making this just a function on the pod itself.
      spec:: {
        Containers(containers):: {
          containers: containers,
        },

        Volumes(volumes):: {
          volumes: volumes,
        },

        DnsPolicy(policy="ClusterFirst"):: {
          dnsPolicy: policy,
        },

        RestartPolicy(policy="Always"):: {
          restartPolicy: policy,
        },
      },
    },
  },

  extensions:: {
    v1beta1: {
      local bases = {
        Deployment: base.New("deployment", "176A7BEF-E577-4EBD-952D-5E8F7BB7AE1A"),
      },

      local ApiVersion = { apiVersion: "extensions/v1beta1" },

      //
      // Deployments.
      //
      deployment:: {
        Default(metadata, spec):
          bases.Deployment + ApiVersion + Kind("Deployment") {
            metadata: metadata,
            spec: spec,
          },

        // TODO: Consider rolling this into `deployment` namespace.
        spec:: {
          ReplicatedPod(replicas, podTemplate):: {
            replicas: replicas,
            template: podTemplate,
          },

          Selector(labels):: {
            selector: {
              matchLabels: labels,
            },
          },

          MinReadySeconds(seconds=0):: {
            minReadySeconds: seconds,
          },

          RollingUpdateStrategy(maxSurge=1, maxUnavailable=1):: {
            strategy: {
              rollingUpdate: {
                maxSurge: maxSurge,
                maxUnavailable: maxUnavailable,
              },
              type: "RollingUpdate",
            },
          },
        },
      },

      IngressSpec(domain, serviceName, servicePort):: {
        rules: [
          {
            host: domain,
            http: {
              paths: [{
                backend: {
                  serviceName: serviceName,
                  servicePort: servicePort,
                }}]
            }
          }
        ]
      },

      // Ingress(fullname, chart): ApiVersion + Metadata(fullname) {
      //   kind: "Ingress",
      // },
    },
  },
}