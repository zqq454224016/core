/*
Copyright 2023 The Kubebb Authors.

Licensed under the Apache License, Version 2.0 (the "License");
you may not use this file except in compliance with the License.
You may obtain a copy of the License at

    http://www.apache.org/licenses/LICENSE-2.0

Unless required by applicable law or agreed to in writing, software
distributed under the License is distributed on an "AS IS" BASIS,
WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
See the License for the specific language governing permissions and
limitations under the License.
*/

package v1alpha1

import (
	corev1 "k8s.io/api/core/v1"
	metav1 "k8s.io/apimachinery/pkg/apis/meta/v1"
)

type InstallMethod string

const (
	// InstallMethodAuto means install directly without confirmation after detecting a new version.
	InstallMethodAuto InstallMethod = "Auto"
	// InstallMethodManual means installation process requires user's permission to proceed.
	InstallMethodManual InstallMethod = "Manual"
)

// SubscriptionSpec defines the desired state of Subscription
type SubscriptionSpec struct {
	// ComponentRef is a reference to the Component
	ComponentRef *corev1.ObjectReference `json:"component"`
	// ComponentPlanInstallMethod is the method used to install the component
	ComponentPlanInstallMethod InstallMethod `json:"componentPlanInstallMethod,omitempty"`
	// Override defines the override settings for the component
	Override []Override `json:"override,omitempty"`
}

// SubscriptionStatus defines the state of Subscription
type SubscriptionStatus struct {
	ConditionedStatus `json:",inline"`
	// HistoryVersions records the component version changes since this subscription created
	// +optional
	HistoryVersions []ComponentVersion `json:"historyVersions,omitempty"`

	// Installed records all componentplans installed, ordered by install time.
	// +optional
	Installed []Installed `json:"installed,omitempty"`

	// RepositoryHealth contains the Subscription's view of its relevant Repository' status.
	// It is used to determine SubscriptionStatusConditions related to Repository
	// +optional
	RepositoryHealth RepositoryHealth `json:"repositoryHealth,omitempty"`
}

type Installed struct {
	// InstalledVersion is the version currently installed in cluster
	// +optional
	InstalledVersion ComponentVersion `json:"installedVersion"`
	// InstalledTime is the time that the version was installed in cluster
	// +optional
	InstalledTime metav1.Time `json:"installedTime"`
	// ComponentPlanRef is a reference to the latest ComponentPlan
	// +optional
	ComponentPlanRef *corev1.ObjectReference `json:"componentPlanRef"`
}

// RepositoryHealth describes the health of a Repository the Subscription knows about.
type RepositoryHealth struct {
	// RepositoryRef is a reference to a Repository.
	RepositoryRef *corev1.ObjectReference `json:"repositoryRef"`

	// LastUpdated represents the last time that the RepositoryHealth changed
	LastUpdated *metav1.Time `json:"lastUpdated"`

	// Healthy is true if the Repository is healthy; false otherwise.
	Healthy bool `json:"healthy"`
}

//+kubebuilder:object:root=true
//+kubebuilder:subresource:status
//+kubebuilder:resource:scope=Namespaced

// Subscription is the Schema for the subscriptions API
type Subscription struct {
	metav1.TypeMeta   `json:",inline"`
	metav1.ObjectMeta `json:"metadata,omitempty"`

	Spec   SubscriptionSpec   `json:"spec,omitempty"`
	Status SubscriptionStatus `json:"status,omitempty"`
}

//+kubebuilder:object:root=true

// SubscriptionList contains a list of Subscription
type SubscriptionList struct {
	metav1.TypeMeta `json:",inline"`
	metav1.ListMeta `json:"metadata,omitempty"`
	Items           []Subscription `json:"items"`
}

func init() {
	SchemeBuilder.Register(&Subscription{}, &SubscriptionList{})
}