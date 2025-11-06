Here is a short document clarifying the two-layer security model for GKE.

## 🔐 GKE Security: The Two-Layer Model (IAM & RBAC)

To perform any action in GKE, your request must pass **two separate security checks**. Think of it as a secure building: Google Cloud IAM is the **front door key**, and Kubernetes RBAC is the **internal vault key**. You must have both.

---

### Layer 1: Google Cloud IAM (The "Front Door")

This is the first check, performed by Google Cloud *before* your request even reaches the cluster.

* **What it controls:** It checks if your Google identity (e.g., `email address`) is **authorized to *attempt* an action** on the GKE cluster resource.
* **Permissions:** These are Google-level permissions, like:
  * `container.clusters.get` (Lets you "see" the cluster)
  * `container.clusters.delete` (Lets you delete the whole cluster)
  * `container.pods.create` (Lets you *attempt* to create a pod)
* **Roles:** This is where Google's predefined roles live, such as `roles/container.admin`, `roles/container.developer`, and `roles/container.viewer`.

---

### Layer 2: Kubernetes RBAC (The "Vault Door")

Once IAM lets you in, your request goes to the Kubernetes API server, which performs its *own* internal check.

* **What it controls:** It checks if the Kubernetes `User` (which GKE maps from your Google ID) is **allowed to perform the action *inside* the cluster**.
* **Permissions:** These are Kubernetes-level verbs and resources, like:
  * `create` on `pods` in the `default` namespace
  * `get` on `secrets` in the `kube-system` namespace
* **Roles:** This is where Kubernetes's internal roles live, like `cluster-admin`, `admin`, `edit`, and `view`.

---

### 🔗 The Connection: How IAM Maps to RBAC Groups

GKE has a "magic" connection that automatically links your Layer 1 IAM role to a powerful Layer 2 RBAC group.

1. **The "Key" (IAM):** Any Google IAM role (like `container.admin`, `developer`, or even `viewer`) that contains the **`container.clusters.get`** permission allows you to authenticate to the cluster.
2. **The "Group" (RBAC):** When GKE sees you have this "key," it *automatically* and *implicitly* places your user (`email address`) into the Kubernetes group **`system:masters`** for that session.
3. **The "Power" (RBAC):** As you verified, the `system:masters` group is, by default, bound to the **`cluster-admin`** role inside Kubernetes.

This is why fixing your Layer 1 IAM role (giving you `container.pods.create` AND `container.clusters.get`) was all you needed to do. The `container.clusters.get` permission automatically gave you `cluster-admin` (Layer 2), and the `container.pods.create` permission satisfied the Layer 1 check, allowing your `node-shell` command to succeed.

### Summary: IAM vs. RBAC

| Feature | Layer 1: Google Cloud IAM | Layer 2: Kubernetes RBAC |
| :--- | :--- | :--- |
| **Controls** | **Google Cloud Resources** (The cluster itself) | **Kubernetes Resources** (Pods, secrets, etc.) |
| **Analogy** | The Building's Front Door | The Internal Vault Door |
| **Permission** | `container.pods.create` | `create` on `pods` |
| **Example Role**| `roles/container.developer` | `cluster-admin` |
| **Identity** | Google Account (`email address`) | Kubernetes `User` (`email address`) |
