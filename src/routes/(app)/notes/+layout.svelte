<script lang="ts">
	import { onMount, getContext } from 'svelte';
	import { WEBUI_NAME, showSidebar, functions, config, user, showArchivedChats, mobile, isDarkMode } from '$lib/stores';
	import { goto } from '$app/navigation';

	import MenuLines from '$lib/components/icons/MenuLines.svelte';
	import UserMenu from '$lib/components/layout/Sidebar/UserMenu.svelte';

	const i18n = getContext('i18n');

	let loaded = false;

    let logoImage: string = "";

	onMount(async () => {
		if (
			!(
				($config?.features?.enable_notes ?? false) &&
				($user?.role === 'admin' || ($user?.permissions?.features?.notes ?? true))
			)
		) {
			// If the feature is not enabled, redirect to the home page
			goto('/');
		}

		loaded = true;
	
		// START Synechron Customization
        const updateDarkMode = () => {
            isDarkMode.set(document.documentElement.classList.contains('dark'));
        };

        // Initial check
        updateDarkMode();

        // Observe changes to the class attribute
        const observer = new MutationObserver(updateDarkMode);
        observer.observe(document.documentElement, { attributes: true, attributeFilter: ['class'] });

        // End of Synechron Customization


        return () => observer.disconnect();
        // END Synechron Customization
	});


	// START Synechron Customization
    // Reactive statement to update logoImage based on conditions
    $: {
        const darkMode = $isDarkMode; // Access the value of isDarkMode
        mobile.subscribe((value) => {
            if (darkMode && value) {
                logoImage = $config.logo_small_dark_image;
            } else if (darkMode && !value) {
                logoImage = $config.logo_dark_image;
            } else if (!darkMode && value) {
                logoImage = $config.logo_small_image;
            } else {
                logoImage = $config.logo_image;
            }
        });
    }
    // END Synechron Customization
</script>

<svelte:head>
	<title>
		{$i18n.t('Notes')} • {$WEBUI_NAME}
	</title>
</svelte:head>

{#if loaded}
	<slot />
{/if}
