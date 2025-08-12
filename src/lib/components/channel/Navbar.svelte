<script lang="ts">
	import { getContext, onMount } from 'svelte';
	import { toast } from 'svelte-sonner';

	import { mobile, showArchivedChats, showSidebar, user, config, isDarkMode } from '$lib/stores';

	import { slide } from 'svelte/transition';
	import { page } from '$app/stores';

	import UserMenu from '$lib/components/layout/Sidebar/UserMenu.svelte';
	import PencilSquare from '../icons/PencilSquare.svelte';
	import Tooltip from '../common/Tooltip.svelte';
	import Sidebar from '../icons/Sidebar.svelte';

	const i18n = getContext('i18n');

	export let channel;

	// START Synechron Customization
    let logoImage: string = "";

    // Watch for changes in dark mode
    onMount(() => {
        const updateDarkMode = () => {
            isDarkMode.set(document.documentElement.classList.contains('dark'));
        };

        // Initial check
        updateDarkMode();

        // Observe changes to the class attribute
        const observer = new MutationObserver(updateDarkMode);
        observer.observe(document.documentElement, { attributes: true, attributeFilter: ['class'] });

        return () => observer.disconnect();
    });

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
    // End Synechron Customization

</script>

<nav class="sticky top-0 z-30 w-full px-1.5 py-1.5 -mb-8 flex items-center drag-region">
	<div
		class=" bg-linear-to-b via-50% from-white via-white to-transparent dark:from-gray-900 dark:via-gray-900 dark:to-transparent pointer-events-none absolute inset-0 -bottom-7 z-[-1]"
	></div>

	<div class=" flex max-w-full w-full mx-auto px-1 pt-0.5 bg-transparent">
		<div class="flex items-center w-full max-w-full">
			{#if $mobile}
				<div
					class="{$showSidebar
						? 'md:hidden'
						: ''} mr-1.5 mt-0.5 self-start flex flex-none items-center text-gray-600 dark:text-gray-400"
				>
					<Tooltip
						content={$showSidebar ? $i18n.t('Close Sidebar') : $i18n.t('Open Sidebar')}
						interactive={true}
					>
						<button
							id="sidebar-toggle-button"
							class=" cursor-pointer flex rounded-lg hover:bg-gray-100 dark:hover:bg-gray-850 transition cursor-"
							on:click={() => {
								showSidebar.set(!$showSidebar);
							}}
						>
							<div class=" self-center p-1.5">
								<Sidebar />
							</div>
						</button>
					</Tooltip>
				</div>
			{/if}

			<div
				class="flex-1 overflow-hidden max-w-full py-0.5
			{$showSidebar ? 'ml-1' : ''}
			"
			>
				{#if channel}
					<div class="line-clamp-1 capitalize font-medium font-primary text-lg">
						{channel.name}
					</div>
				{/if}
			</div>

			<div class="self-start flex flex-none items-center text-gray-600 dark:text-gray-400">
				{#if $user !== undefined}
					<UserMenu
						className="max-w-[240px]"
						role={$user?.role}
						help={true}
						on:show={(e) => {
							if (e.detail === 'archived-chat') {
								showArchivedChats.set(true);
							}
						}}
					>
						<button
							class="select-none flex rounded-xl p-1.5 w-full hover:bg-gray-50 dark:hover:bg-gray-850 transition"
							aria-label="User Menu"
						>
							<div class=" self-center">
								<img
									src={logoImage ?? $user?.profile_image_url}
									class="size-6 object-cover rounded-full"
									alt="User profile"
									draggable="false"
                                    style="width: {logoImage ? 'auto' : '1.5rem'}; height: {logoImage ?  '2rem' : '1.5rem'};"
								/>
							</div>
						</button>
					</UserMenu>
				{/if}
			</div>
		</div>
	</div>
</nav>
